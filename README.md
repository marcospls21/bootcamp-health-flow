Aqui está o seu `README.md` totalmente atualizado! 🚀

Adicionei as novas funcionalidades (Login, Dashboard, Banco de Dados RDS), as ferramentas de monitoramento (Grafana/Prometheus) e os comandos exatos que usamos para recuperar as senhas e URLs.

---

# 🏥 HealthFlow - DevOps & SRE Cloud Lab

O **HealthFlow** é uma plataforma de gestão de saúde digital simulada. Este laboratório demonstra um ciclo de vida moderno de Engenharia de Software e Cloud, migrando de uma mentalidade legada para **Cloud Native**.

O projeto vai além do básico, implementando um **Portal do Paciente** completo com autenticação, banco de dados relacional e painéis administrativos, tudo rodando sobre Kubernetes.

---

## 🏗️ Arquitetura e Componentes

O projeto utiliza uma arquitetura de microsserviços sobre Kubernetes (EKS) com persistência de dados gerenciada.

### 🧩 Microserviços & Aplicações:

1. **Core App (Portal):** Aplicação Python (Flask) com:
* Tela de Login e Cadastro de Pacientes.
* **Dashboard Administrativo** para gestão de consultas.
* Conexão com Banco de Dados PostgreSQL.


2. **Apresentação:** Aplicação Nginx servindo o deck executivo e vídeo de demonstração do projeto.

### ☁️ Infraestrutura & Ferramentas:

* **Orquestração:** AWS EKS (Kubernetes).
* **Banco de Dados:** Amazon RDS (PostgreSQL) provisionado via Terraform.
* **GitOps:** ArgoCD sincronizando o estado do cluster com o Git.
* **IaC:** Terraform provisionando VPC, EKS, RDS, Security Groups e Helm Charts.
* **Observabilidade:** Prometheus & Grafana (Stack de Monitoramento).
* **CI/CD:** GitHub Actions (Security Scan, Build Docker, Deploy Infra).

---

## ⚙️ Guia de Configuração (Passo a Passo)

### 1. Configurar o Repositório Remoto (Git)

Aponte o projeto para o seu GitHub para rodar as Actions:

```bash
git remote remove origin
git remote add origin https://github.com/SEU_USUARIO/NOME_DO_SEU_REPO.git
git branch -M main
git push -u origin main

```

### 2. Configurar Segredos no GitHub

Em **Settings > Secrets and variables > Actions**, adicione:

| Secret | Descrição |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | Do AWS Academy (AWS Details). |
| `AWS_SECRET_ACCESS_KEY` | Do AWS Academy. |
| `AWS_SESSION_TOKEN` | Do AWS Academy (**Renovar a cada 4h**). |
| `DOCKER_USERNAME` | Seu usuário Docker Hub. |
| `DOCKER_PASSWORD` | Senha/Token Docker Hub. |

### 3. Ajustar Variáveis

* **`terraform/variables.tf`**: Atualize a `repo_url` para o seu GitHub.
* **`k8s/core/deployment.yaml`**: Verifique se a imagem Docker aponta para o seu usuário (`SEU_USER/health-core:latest`).

---

## 🚀 Executando o Lab (Deploy)

1. Vá na aba **Actions** do GitHub e dispare o workflow **🧪 Lab Lifecycle**.
2. Aguarde o pipeline finalizar (Build das imagens + Terraform Apply).
* *Nota:* A criação do RDS pode levar cerca de 10-15 minutos.


3. Atualize suas credenciais locais para acessar o cluster:
```bash
aws eks update-kubeconfig --region us-east-1 --name health-flow-cluster

```



---

## 🌐 Acessando as Aplicações e Ferramentas

Após o deploy, a AWS leva de **2 a 5 minutos** para propagar os DNS dos LoadBalancers. Se der erro de "Site não encontrado", aguarde um pouco.

### 1. 🏥 Portal HealthFlow (Login & Dashboard)

Acesse o sistema principal, faça login (`admin`/`Password123!`) ou cadastre novos pacientes.

* **Obter URL:**
```bash
kubectl get svc core-service -n health-core -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```



### 2. 🐙 ArgoCD (GitOps)

Gerenciamento contínuo do deploy.

* **Obter URL:**
```bash
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```


* **Obter Senha (Usuário: `admin`):**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

```



### 3. 📊 Grafana (Observabilidade)

Dashboards de métricas do cluster e dos pods.

* **Obter URL:**
```bash
kubectl get svc prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```


* **Obter Senha (Usuário: `admin`):**
```bash
kubectl get secret --namespace monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

```



### 4. 📺 Apresentação (Vídeo)

* **Obter URL:**
```bash
kubectl get svc video-service -n health-video -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```



---

## 📂 Estrutura do Projeto

```text
.
├── .github/workflows/     # Pipeline CI/CD
├── argo-applications.yaml # Manifesto Mestre do ArgoCD
├── k8s/
│   ├── core/              # Manifestos do App Principal (com Env Vars do BD)
│   ├── video/             # Manifestos da Apresentação
├── src/
│   ├── core-app/          # Python Flask + HTML Templates (Login/Dash)
│   └── video/             # Nginx + Vídeo Estático
├── terraform/             # IaC (EKS, VPC, RDS, Helm)
└── README.md              # Documentação

```

---

## ⚠️ Troubleshooting (Resolução de Problemas)

* **Erro `spec.selector: field is immutable` no ArgoCD:**
* Isso ocorre se você mudou as labels do Deployment.
* **Solução:** No ArgoCD, clique em **Sync**, selecione a opção **Replace** e confirme. Isso força a recriação do recurso.


* **Site não abre (Timeout):**
* Verifique o **Security Group** dos Worker Nodes no Console EC2. Garanta que há uma regra de entrada liberando tráfego de `0.0.0.0/0` para "All Traffic".


* **Erro de Conexão com Banco de Dados:**
* Verifique se as variáveis de ambiente (`DB_HOST`) foram injetadas corretamente no Pod: `kubectl describe pod -n health-core`.
* Confirme se o Security Group do RDS permite conexão vinda do Security Group do EKS (Porta 5432).