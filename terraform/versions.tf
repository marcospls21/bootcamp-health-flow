terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Garante compatibilidade com a versão 5
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    # Necessário para o ArgoCD funcionar bem
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }

  # --- CONFIGURAÇÃO DO BACKEND S3 (IMPORTANTE PARA O CI/CD) ---
  # 1. Crie um Bucket S3 na sua conta AWS com um nome único (ex: healthflow-state-SEUNOME).
  # 2. Substitua o campo 'bucket' abaixo pelo nome que você criou.
  # 3. Se estiver no AWS Academy e não puder criar bucket, comente essas linhas (mas o CD automático pode falhar).

  backend "s3" {
    bucket = "healthflow-terraform-state-marcos" # <--- TROQUE PELO SEU BUCKET
    key    = "healthflow/terraform.tfstate"
    region = "us-east-1"
  }
}
