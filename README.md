# 🏥 HealthFlow - DevOps & SRE Cloud Lab

O **HealthFlow** é uma plataforma de gestão de saúde digital simulada, projetada para demonstrar um ciclo de vida moderno de Engenharia de Software e Cloud. Este laboratório implementa **Infraestrutura como Código (IaC)**, **Containerização**, **Orquestração**, **CI/CD** e **Observabilidade Avançada**.

O projeto foi adaptado especificamente para rodar dentro das restrições de segurança e orçamento do ambiente **AWS Academy**.

---

## 🏗️ Arquitetura e Infraestrutura

O projeto utiliza uma arquitetura baseada em microsserviços rodando sobre Kubernetes gerenciado (EKS).

### Componentes Principais:

1. **Aplicação (Core):** Desenvolvida em Python (Flask), servindo interfaces web dinâmicas.
2. **Containerização:** Docker é usado para empacotar a aplicação e suas dependências.
3. **Orquestração (AWS EKS):** Cluster Kubernetes que gerencia a disponibilidade e escalabilidade dos pods.
4. **Infraestrutura (Terraform):** Provisiona VPC, Subnets, Security Groups, Cluster EKS e Node Groups de forma automatizada.
5. **Observabilidade (Datadog):** Agente instalado via Helm Chart para coleta de métricas, logs e APM (Application Performance Monitoring).
6. **Pipeline (GitHub Actions):** Automação completa de Segurança (Trivy), Build (Docker Hub) e Deploy (Terraform).

---

## 🚀 Moderno vs. Legado: Por que mudar?

Este projeto demonstra a evolução do "Modelo Tradicional" para o "Modelo Cloud Native/DevOps".

| Característica | 🐢 Modelo Tradicional (Legado) | 🐇 Modelo HealthFlow (Moderno) |
| --- | --- | --- |
| **Infraestrutura** | Servidores físicos ou VMs configuradas manualmente ("Snowflakes"). | **IaC (Terraform):** Infraestrutura descartável, versionada e reprodutível em minutos. |
| **Deploy** | Cópia manual de arquivos (FTP/SSH), risco alto de erro humano. | **CI/CD Automatizado:** Pipeline que testa, constrói e entrega sem intervenção humana. |
| **Escalabilidade** | Limitada ao hardware físico; upgrades demorados. | **Elástica (Kubernetes):** Pods e Nodes escalam horizontalmente conforme a demanda. |
| **Monitoramento** | Reativo (alguém avisa que caiu). Logs espalhados em arquivos. | **Observabilidade (Datadog):** Proativo. Dashboards centralizados, alertas e tracing em tempo real. |
| **Ambiente** | "Funciona na minha máquina", mas falha em produção. | **Containers (Docker):** O mesmo ambiente exato roda no dev, teste e produção. |

---

## 📋 Pré-requisitos

Para rodar este laboratório, você precisará de contas ativas nas seguintes plataformas:

1. **AWS Academy:** Acesso ao ambiente "Learner Lab".
2. **GitHub:** Para hospedar este repositório e rodar as Actions.
3. **Docker Hub:** Conta gratuita para armazenar as imagens da aplicação.
4. **Datadog:** Conta (Trial ou Free) para obter a API Key de monitoramento.

---

## ⚙️ Guia de Configuração (Para Clonar e Rodar)

Siga esta ordem exata para configurar o ambiente.

### 1. Configurar o Repositório Remoto (Git)

Se você clonou este projeto, a URL de origem (`origin`) ainda aponta para o repositório original. Para rodar as Actions na **sua** conta, você deve apontar para o seu próprio repositório.

1. Crie um **novo repositório vazio** no seu GitHub (ex: `meu-lab-devops`).
2. No terminal do projeto, execute:
```bash
# Remove o vínculo com o repositório original
git remote remove origin

# Adiciona o seu repositório como nova origem
git remote add origin https://github.com/SEU_USUARIO/NOME_DO_SEU_REPO.git

# Garante que está na branch principal
git branch -M main

# Envia o código para o seu GitHub
git push -u origin main

```



### 2. Configurar Segredos no GitHub (Obrigatório)

Vá em **Settings > Secrets and variables > Actions** e crie as seguintes variáveis. Sem elas, o pipeline falhará.

| Nome da Secret | Valor / Descrição |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | Copie do painel AWS Academy (AWS Details). |
| `AWS_SECRET_ACCESS_KEY` | Copie do painel AWS Academy. |
| `AWS_SESSION_TOKEN` | Copie do painel AWS Academy (**Crucial!** As credenciais expiram a cada 4h). |
| `DOCKER_USERNAME` | Seu usuário do Docker Hub (ex: `joaosilva`). |
| `DOCKER_PASSWORD` | Sua senha ou Token de Acesso do Docker Hub. |
| `TF_VAR_datadog_api_key` | Sua API Key gerada no painel do Datadog (Organization Settings > API Keys). |

### 3. Ajustar Variáveis do Terraform ⚠️ (CRUCIAL)

Você precisa editar os arquivos do Terraform para que eles reconheçam a sua conta da AWS Academy e o seu repositório GitHub.

#### A. Atualizar ARNs das Roles (main.tf)

No AWS Academy, você deve usar roles pré-existentes e os IDs mudam a cada lab.

1. No Console AWS, vá em **IAM > Roles**.
2. Copie o ARN da `LabEksClusterRole` e da `LabEksNodeRole`.
3. No arquivo `terraform/main.tf`, atualize o bloco `locals`:
```hcl
locals {
  # ATUALIZE COM SEUS VALORES REAIS
  cluster_role_arn = "arn:aws:iam::SEU_ID:role/LabEksClusterRole-XXXX"
  node_role_arn    = "arn:aws:iam::SEU_ID:role/LabEksNodeRole-XXXX"
}

```



#### B. Atualizar URL do Repositório (variables.tf)

O ArgoCD precisa saber onde buscar os arquivos Kubernetes. Se você não mudar isso, ele vai olhar para o repositório do criador do curso, e não para o seu.

1. Abra o arquivo `terraform/variables.tf`.
2. Encontre a variável (geralmente chamada `repo_url` ou `project_url`).
3. Altere o `default` para a URL do **seu** GitHub:
```hcl
variable "repo_url" {
  description = "URL do repositório Git"
  # COLOQUE A URL DO SEU NOVO REPOSITÓRIO AQUI
  default     = "https://github.com/SEU_USUARIO/NOME_DO_SEU_REPO"
}

```



### 4. Ajustar a Imagem Docker no Kubernetes

O arquivo de deploy do Kubernetes precisa saber qual é o **seu** repositório Docker.

1. Abra o arquivo `k8s/core/deployment.yaml`.
2. Encontre a linha `image:`.
3. Substitua pelo seu usuário:
```yaml
# Antes:
image: USUARIO_ANTIGO/health-core:latest

# Depois (exemplo):
image: joaosilva/health-core:latest

```


4. Salve e faça o commit de todas as alterações.

---

## 🧪 Executando o Laboratório (Lab Lifecycle)

Este projeto usa um fluxo especial chamado **"Lab Lifecycle"** para economizar créditos da AWS. Ele cria, espera você usar, e destrói tudo automaticamente.

1. Vá na aba **Actions** do GitHub.
2. Selecione o workflow **🧪 Lab Lifecycle**.
3. Clique em **Run workflow**.
4. Escolha o tempo de duração (ex: **60 minutos**).
5. O Pipeline fará:
* 🛡️ Scan de segurança (Trivy).
* 🐳 Build & Push da imagem Docker.
* 🏗️ Provisionamento da Infra (Terraform Apply).
* ⏳ **Pausa:** O sistema ficará "rodando" pelo tempo que você escolheu.
* 🧨 **Auto-Destroy:** Ao final do tempo (ou se você cancelar), ele destrói tudo.



---

## 🌐 Acessando a Aplicação

Após o Terraform finalizar a criação (aprox. 15 min), siga os passos para acessar:

### 1. Atualizar Credenciais Locais

No seu terminal (com AWS CLI configurado):

```bash
aws eks update-kubeconfig --region us-east-1 --name health-flow-cluster

```

### 2. Verificar os Pods

```bash
kubectl get pods -n health-core

```

*Aguarde até o status estar como `Running`.*

### 3. Acessar via Port-Forward (Recomendado)

Como não usamos LoadBalancer público para economizar custos:

```bash
kubectl port-forward svc/core-service -n health-core 9090:80

```

Acesse no navegador:

* **Home:** [http://localhost:9090](https://www.google.com/search?q=http://localhost:9090)
* **Login:** [http://localhost:9090/login.html](https://www.google.com/search?q=http://localhost:9090/login.html)

---

## 📂 Estrutura do Projeto

```text
.
├── .github/workflows/
│   └── lab-lifecycle.yml  # Pipeline mestre (Security > Build > Deploy > Wait > Destroy)
├── k8s/
│   ├── core/              # Manifestos da Aplicação Principal
│   └── video/             # Manifestos do Serviço de Vídeo (Placeholder)
├── src/
│   └── core-app/          # Código Fonte Python (Flask) + Dockerfile
├── terraform/             # Código IaC
│   ├── main.tf            # Definição do EKS, Helm Charts (Datadog) e Locals das Roles
│   ├── vpc.tf             # Rede
│   ├── variables.tf       # Variáveis gerais (URL do Git)
│   └── outputs.tf         # Saídas (Comandos de conexão)
└── README.md              # Documentação

```

---

## ⚠️ Solução de Problemas Comuns

* **Erro `Authentication failed` no Git Push:** Você esqueceu de executar o **Passo 1** e trocar a URL de origem para o seu repositório.
* **ArgoCD não sincroniza minhas mudanças:** Você esqueceu de atualizar a variável `repo_url` no `variables.tf` (**Passo 3B**).
* **Erro de Permissão (Roles):** Você esqueceu de atualizar o `cluster_role_arn` e `node_role_arn` no `main.tf` (**Passo 3A**).
* **Erro `403 Forbidden` no Terraform:** Suas credenciais da AWS Academy expiraram. Gere novas no portal e atualize as Secrets do GitHub.