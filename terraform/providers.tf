provider "aws" {
  region = "us-east-1"
}

# 1. Este bloco gera o token de autenticação dinâmico
data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

# 2. Provider Kubernetes
provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# 3. Provider Helm
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# 4. Provider Kubectl (O que estava dando erro de localhost!)
provider "kubectl" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}
