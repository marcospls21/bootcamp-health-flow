variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "vpc_id" {
  description = "VPC onde o cluster será criado"
  type        = string
}

variable "private_subnets" {
  description = "Subnets privadas onde os nodes rodarão"
  type        = list(string)
}

variable "aws_region" {
  type        = string
}

variable "aws_access_key" {
  type        = string
}

variable "aws_secret_key" {
  type        = string
}

variable "aws_session_token" {
  type        = string
}

variable "cluster_role_arn" {
  description = "Optional existing IAM Role ARN to use for the EKS cluster. If empty, the module will create the role."
  type        = string
  default     = ""
}

variable "node_role_arn" {
  description = "Optional existing IAM Role ARN to use for EKS node group. If empty, the module will create the role."
  type        = string
  default     = ""
}