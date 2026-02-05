variable "vpc_id" {
  description = "VPC onde o ALB será criado"
  type        = string
}

variable "public_subnets" {
  description = "Subnets públicas do ALB"
  type        = list(string)
}

