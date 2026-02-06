variable "github_repo_url" {
  description = "URL do Repositório GitHub para o ArgoCD monitorar"
  type        = string
  # SUBSTITUA PELA URL DO SEU REPOSITÓRIO (ex: https://github.com/seu-user/health-flow)
  default = "https://github.com/marcospls21/bootcamp-health-flow"
}

variable "datadog_api_key" {
  description = "Datadog API Key para coleta de métricas e logs"
  type        = string
  sensitive   = true
}

# --- NOVAS VARIÁVEIS DYNATRACE ---
variable "dynatrace_api_url" {
  description = "URL do ambiente Dynatrace (Tenant)"
  type        = string
}

variable "dynatrace_api_token" {
  description = "Token de API do Dynatrace (PaaS Token)"
  type        = string
  sensitive   = true
}
