provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token # Obrigatório para AWS Academy
  dynamic "assume_role" {
    for_each = var.lab_role_arn != "" ? [var.lab_role_arn] : []
    content {
      role_arn = assume_role.value
    }
  }
}

module "network" {
  source = "../../modules/network"

  env    = "prod"
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b"]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_app_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  private_data_subnets = [
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "healthflow-prod"
  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_app_subnets
  aws_region      = var.aws_region
  aws_access_key  = var.aws_access_key
  aws_secret_key  = var.aws_secret_key
  aws_session_token = var.aws_session_token
  cluster_role_arn = var.cluster_role_arn
  node_role_arn    = var.node_role_arn
}

module "alb" {
  source = "../../modules/alb"

  vpc_id         = module.network.vpc_id
  public_subnets = module.network.public_subnets
}

