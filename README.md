🏥 HealthFlow - DevOps & Cloud Engineering Lab
O HealthFlow é uma plataforma de gestão de saúde digital simulada, projetada para demonstrar um ciclo completo de Engenharia de Cloud e SRE. Este laboratório implementa infraestrutura como código (IaC), orquestração de containers, GitOps e observabilidade.

O projeto foi adaptado para rodar dentro das restrições de segurança do ambiente AWS Academy.
------------------------------------------------------------------
🏗️ Arquitetura e Tecnologias
Cloud Provider: AWS (VPC, EKS, RDS, S3).

IaC: Terraform (Backend S3 Remoto).

Orquestração: Amazon EKS (Kubernetes v1.29).

Banco de Dados: Amazon RDS (PostgreSQL 14).

GitOps: ArgoCD (Continuous Delivery).

CI/CD: GitHub Actions.

Monitoramento: Datadog Agent (Logs & Métricas).

Aplicação: Python Flask (Backend + Frontend renderizado).
------------------------------------------------------------------
📋 Pré-requisitos (AWS Academy)
Como este laboratório roda no AWS Academy, existem passos manuais obrigatórios antes da automação:

Conta AWS Academy: Sessão ativa (o token expira a cada 4 horas).

Datadog Account: Uma conta (Trial ou Free) para obter a API Key.

Bucket S3 (Manual):

Você deve criar manualmente um Bucket S3 na região us-east-1 para guardar o estado do Terraform.

Nome sugerido: terraform-state-health-flow (deve ser único globalmente).

Se não criar isso, o deploy falhará.
------------------------------------------------------------------
🚀 Passo a Passo: Configuração e Deploy

1. Configurar Segredos no GitHubNo seu repositório, vá em Settings > Secrets and variables > Actions e adicione:Nome do SecretDescriçãoAWS_ACCESS_KEY_IDSua Access Key do AWS Academy.AWS_SECRET_ACCESS_KEYSua Secret Key do AWS Academy.AWS_SESSION_TOKENSeu Session Token (Obrigatório no Academy).TF_VAR_datadog_api_keySua API Key gerada no painel do Datadog.

2. Ajustar o Backend do Terraform
Abra o arquivo terraform/providers.tf e certifique-se de que o nome do bucket corresponde ao que você criou manualmente:

Terraform
backend "s3" {
  bucket = "terraform-state-health-flow" # <--- SEU BUCKET AQUI
  key    = "health-flow/terraform.tfstate"
  region = "us-east-1"
}

3. Executar o Deploy (GitHub Actions)
Faça um Push na branch main.

Acesse a aba Actions no GitHub.

O workflow Infra Deploy será iniciado automaticamente.

Ele provisionará a VPC, Cluster EKS, RDS e instalará o ArgoCD e o Datadog.

Tempo estimado: 15 a 20 minutos.

------------------------------------------------------------------
🌐 Acessando a Aplicação
Após o sucesso do pipeline, você precisa conectar ao cluster para pegar os dados de acesso.

1. Configurar acesso local (kubectl)

Bash
aws eks update-kubeconfig --region us-east-1 --name health-flow-cluster

2. Acessar o Portal Web (HealthFlow)
Para garantir o acesso rápido (bypass de DNS), use o Port-Forward:

Bash
kubectl port-forward svc/core-service -n health-core 9090:80

Acesse no navegador: http://localhost:9090

3. Acessar o ArgoCD (GitOps)
Para ver o status de sincronização das aplicações:

1. Obter senha de admin

Bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

2. Acessar Painel:

Bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
Acesse: https://localhost:8080 (Usuário: admin)
------------------------------------------------------------------
📊 Observabilidade (Datadog)
Se a API Key foi configurada corretamente, o cluster enviará dados automaticamente.

Acesse app.datadoghq.com.

Vá em Infrastructure List para ver os nós do EKS.

Vá em Logs para ver os logs dos containers health-flow-core e health-flow-video.
------------------------------------------------------------------
🧨 Como Destruir (Evitar Custos!)
Para limpar o laboratório e não consumir todos os créditos do Academy:

Vá na aba Actions do GitHub.

Selecione o workflow 🧨 Terraform Destroy (Manual) na lista lateral.

Clique em Run workflow.

Digite DESTROY na caixa de confirmação e execute.

⚠️ Atenção: Se o terraform destroy falhar (por perda de estado), você deve apagar manualmente na AWS nesta ordem: Load Balancers (EC2) -> Node Groups (EKS) -> Cluster (EKS) -> RDS -> VPC.
------------------------------------------------------------------
📝 Estrutura do Projeto
Plaintext
.
├── .github/workflows/   # Pipelines de CI/CD (Deploy e Destroy)
├── k8s/                 # Manifestos Kubernetes (Deployments, Services)
├── src/
│   └── core-app/        # Código Python Flask + Templates HTML
├── terraform/           # Código IaC (Main, VPC, EKS, RDS, Helm)
└── README.md            # Documentação