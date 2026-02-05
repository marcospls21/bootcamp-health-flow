variable "aws_region" {
  description = "AWS region for provider"
  type        = string
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "aws_session_token" {
  description = "AWS session token (optional for temporary creds)"
  type        = string
}

variable "lab_role_arn" {
  description = "Optional ARN of the AWS Academy LabRole to assume (provide a role ARN, not an instance-profile)"
  type        = string
  default     = ""
}

variable "cluster_role_arn" {
  description = "Optional existing IAM Role ARN to use for the EKS cluster"
  type        = string
  default     = ""
}

variable "node_role_arn" {
  description = "Optional existing IAM Role ARN to use for EKS node group"
  type        = string
  default     = ""
}
