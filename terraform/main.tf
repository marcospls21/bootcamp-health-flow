data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

# --- DEFINIÇÃO DAS ROLES (Garantia de Fallback) ---
locals {
  # 1. A Role Padrão do Academy (Tentativa Principal)
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  # 2. As Roles Específicas que você forneceu (Segurança)
  # Se a LabRole falhar, troque as variáveis 'used_cluster_role' e 'used_node_role' abaixo por estas
  specific_cluster_role = "arn:aws:iam::074442581040:role/c196815a5042644l13691097t1w074442-LabEksClusterRole-z4U15qTttNJF"
  specific_node_role    = "arn:aws:iam::074442581040:role/c196815a5042644l13691097t1w074442581-LabEksNodeRole-gSRwpwgLZvgg"

  # --- CONFIGURAÇÃO ATIVA ---
  # Mude aqui se o 'terraform apply' der erro de permissão com a LabRole
  # Padrão: local.lab_role_arn
  used_cluster_role = local.lab_role_arn
  used_node_role    = local.lab_role_arn
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

# --- EKS Cluster ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "health-flow-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # --- CONFIGURAÇÃO DE ROLES ---
  create_iam_role = false
  iam_role_arn    = local.used_cluster_role # Usa a role definida no topo

  enable_irsa               = false
  manage_aws_auth_configmap = false # Gerenciamos manualmente abaixo

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 2
      desired_size   = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      create_iam_role = false
      iam_role_arn    = local.used_node_role # Usa a role definida no topo
    }
  }
}

# --- AWS-AUTH (A Garantia de Acesso) ---
# Aqui mapeamos TANTO a LabRole QUANTO a Role Específica.
# Assim, qualquer uma que for usada terá permissão de entrar no cluster.
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      # Opção 1: LabRole (Padrão)
      {
        rolearn  = local.lab_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      # Opção 2: Role Específica de Node (Backup)
      # Adicionamos preventivamente. Se os nodes usarem essa role, eles entram.
      {
        rolearn  = local.specific_node_role
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
    mapUsers = yamlencode([])
  }

  depends_on = [module.eks]
}

# --- RDS Postgres ---
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

  manage_master_user_password = false
  password                    = "Password123!"

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids             = module.vpc.public_subnets
  publicly_accessible    = true
  skip_final_snapshot    = true
  family                 = "postgres14"
}

# --- Nginx Ingress ---
resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "nginx-system"
  create_namespace = true
  version          = "4.7.1"
  depends_on       = [module.eks, kubernetes_config_map.aws_auth]

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# --- ArgoCD ---
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"
  depends_on       = [module.eks, kubernetes_config_map.aws_auth]

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}

# --- Argo Apps ---
resource "kubernetes_manifest" "app_core" {
  depends_on = [helm_release.argocd]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "health-flow-core"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.github_repo_url
        targetRevision = "HEAD"
        path           = "k8s/core"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "health-core"
      }
      syncPolicy = {
        automated   = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}

resource "kubernetes_manifest" "app_video" {
  depends_on = [helm_release.argocd]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "health-flow-video"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.github_repo_url
        targetRevision = "HEAD"
        path           = "k8s/video"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "health-video"
      }
      syncPolicy = {
        automated   = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}
