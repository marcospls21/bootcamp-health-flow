variable "env" {
  description = "Ambiente (dev, stage, prod)"
  type        = string
}

variable "region" {
  description = "Região AWS"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR principal da VPC"
  type        = string
}

variable "public_subnets" {
  description = "Lista de CIDRs das subnets públicas"
  type        = list(string)
}

variable "private_app_subnets" {
  description = "Lista de CIDRs das subnets privadas de aplicação"
  type        = list(string)
}

variable "private_data_subnets" {
  description = "Lista de CIDRs das subnets privadas de dados"
  type        = list(string)
}

variable "azs" {
  description = "Lista de Availability Zones"
  type        = list(string)
}

