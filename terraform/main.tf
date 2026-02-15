# --- DADOS E CONTEXTO ---
data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

# --- DEFINIÇÃO DAS ROLES (AWS Academy) ---
locals {
  # ARNs fornecidos pelo ambiente Lab
  cluster_role_arn = "arn:aws:iam::074442581040:role/c196815a5042644l13691097t1w074442-LabEksClusterRole-z4U15qTttNJF"
  node_role_arn    = "arn:aws:iam::074442581040:role/c196815a5042644l13691097t1w074442581-LabEksNodeRole-gSRwpwgLZvgg"
}

# --- VPC ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "health-flow-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = { Project = "Health-Flow" }
}

# --- SEGURANÇA: SG PARA O BANCO DE DADOS ---
resource "aws_security_group" "db_sg" {
  name        = "health-flow-db-sg"
  description = "Permite acesso ao RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EKS CLUSTER ---
resource "aws_eks_cluster" "this" {
  name     = "health-flow-cluster"
  role_arn = local.cluster_role_arn
  version  = "1.32"

  vpc_config {
    subnet_ids             = module.vpc.private_subnets
    endpoint_public_access = true
  }

  tags = { Project = "Health-Flow" }
}

# --- EKS NODE GROUP ---
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "health-flow-workers"
  node_role_arn   = local.node_role_arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  depends_on = [aws_eks_cluster.this]

  tags = { Project = "Health-Flow" }
}

# --- RDS POSTGRES ---
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.1"

  identifier = "health-flow-db"

  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "healthflowdb"
  username          = "dbadmin"
  port              = 5432

  family = "postgres14"

  manage_master_user_password = false
  password                    = "Password123!"

  create_db_subnet_group = true
  subnet_ids             = module.vpc.public_subnets
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = true
  skip_final_snapshot = true
}

# --- HELM: Ingress Nginx ---
resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "nginx-system"
  create_namespace = true
  version          = "4.7.1"

  depends_on = [aws_eks_node_group.this]

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# --- HELM: ArgoCD ---
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

  depends_on = [aws_eks_node_group.this]

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}

# --- HELM: Stack de Observabilidade (Prometheus + Grafana) ---
resource "helm_release" "kube_prometheus_stack" {
  name             = "prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }
}

# --- HELM: Loki (Logs) ---
resource "helm_release" "loki_stack" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  namespace        = "monitoring"
  create_namespace = true

  depends_on = [
    helm_release.kube_prometheus_stack
  ]
}

# --- ARGOCD APPLICATIONS DEPLOY ---

# 1. Processador de documentos para arquivos com separador "---"
data "kubectl_file_documents" "argo_docs" {
  content = file("${path.module}/../argo-applications.yaml")
}

# 2. Deploy das Apps via ArgoCD
resource "kubectl_manifest" "argocd_apps" {
  for_each  = data.kubectl_file_documents.argo_docs.manifests
  yaml_body = each.value

  # Garante que as aplicações só tentem subir após o ArgoCD e os Nodes estarem prontos
  depends_on = [
    aws_eks_node_group.this,
    helm_release.argocd
  ]
}

# --- NAMESPACES ADICIONAIS ---
resource "kubernetes_namespace" "health_core" {
  metadata { name = "health-core" }
  depends_on = [aws_eks_node_group.this]
}

# --- REGRA ADICIONAL: LIBERAR TRÁFEGO PARA O CLUSTER (Acesso ao Site e DBeaver) ---

# 1. Liberar porta 80 (Site) nos Nodes do EKS
resource "aws_security_group_rule" "allow_http_nodes" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Permite acesso ao site de qualquer lugar [cite: 2026-02-14]
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

# 2. Ajuste na regra do Banco para permitir o DBeaver da sua casa
# Substituímos a regra interna por uma que aceita conexões externas [cite: 2026-02-14]
resource "aws_security_group_rule" "allow_dbeaver_rds" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Necessário para o DBeaver funcionar fora da VPC [cite: 2026-02-14]
  security_group_id = aws_security_group.db_sg.id
}
