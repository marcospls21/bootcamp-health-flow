# 🏥 HealthFlow - DevOps & SRE Cloud Lab

**HealthFlow** é uma plataforma de gestão de saúde digital *Cloud Native*. Este laboratório simula um ambiente real de **Engenharia de Software e SRE**, demonstrando a migração de sistemas, orquestração de contêineres e telemedicina.

O projeto implementa uma arquitetura de microsserviços rodando no **AWS EKS (Kubernetes)**, com banco de dados gerenciado **RDS (PostgreSQL)** e pipelines de CI/CD modernos.

---

## 🏗️ Arquitetura e Componentes

O sistema é composto por microsserviços independentes e ferramentas de observabilidade:

### 🧩 Microserviços:

1. **Core App (Portal do Médico/Paciente):**
* Aplicação em **Python (Flask)**.
* Funcionalidades: Login seguro, Cadastro de Pacientes (com endereço/CPF), Agendamento de Consultas e Dashboard Financeiro.
* Persistência: Conecta-se ao **Amazon RDS** (PostgreSQL).


2. **Video App (Telemedicina):**
* Aplicação Frontend em **Nginx** + **Jitsi Meet API**.
* Funcionalidades: Salas de videoconferência seguras e dinâmicas criadas automaticamente para cada consulta.



### ☁️ Infraestrutura & Ferramentas:

* **IaC:** **Terraform** (Provisiona VPC, EKS, RDS, Security Groups e Helm Releases).
* **Orquestração:** **AWS EKS** (Kubernetes 1.32).
* **GitOps:** **ArgoCD** (Sincronização contínua do estado do cluster).
* **Observabilidade:** **Prometheus & Grafana** (Métricas de infra e aplicação).
* **CI/CD:** **GitHub Actions** (Build, Security Scan e Push para Docker Hub).

---

## ⚙️ Guia de Configuração (Passo a Passo)

### 1. Provisionar Infraestrutura (Terraform)

Navegue até a pasta `terraform` e inicie o ambiente. Isso criará o cluster EKS e o banco RDS.

```bash
cd terraform
terraform init
terraform apply -auto-approve

```

* *Nota:* O processo leva cerca de **15 a 20 minutos**.
* **Importante:** Atualize as variáveis no arquivo `terraform.tfvars` ou `main.tf` com seus ARNs do AWS Academy se necessário.

### 2. Configurar o Banco de Dados (RDS)

O `app.py` já possui um sistema de *Auto-Init*, mas para garantir a estrutura correta (ou resetar dados), conecte-se via **DBeaver** e rode:

```sql
-- Criação da Tabela de Usuários (Login/Cadastro)
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nome_completo VARCHAR(150) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    cpf VARCHAR(20) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    cep VARCHAR(15),
    rua VARCHAR(150),
    numero VARCHAR(20),
    complemento VARCHAR(100),
    senha VARCHAR(100) NOT NULL
);

-- Criação da Tabela de Consultas (Dashboard)
CREATE TABLE IF NOT EXISTS consultas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    especialidade VARCHAR(100) NOT NULL,
    horario VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pendente'
);

```

### 3. Deploy das Aplicações (GitOps)

Após o Terraform finalizar, conecte-se ao cluster e aplique o manifesto mestre do ArgoCD:

```bash
# Atualizar Kubeconfig
aws eks update-kubeconfig --region us-east-1 --name health-flow-cluster

# Aplicar App of Apps
kubectl apply -f argo-applications.yaml

```

---

## 🌐 Acessando o Sistema

Utilize os comandos abaixo para obter as URLs públicas (LoadBalancers) geradas pela AWS.

### 1. 🏥 Portal Principal (HealthFlow)

Acesse para realizar Login, Cadastro de Pacientes e ver o Dashboard.

```bash
kubectl get svc core-service -n health-core -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```

* **Login Admin:** `admin` / `Password123!`
* **Login Paciente:** Utilize os dados criados na tela "Criar Nova Conta".

### 2. 📹 Serviço de Telemedicina (Video App)

Este serviço é chamado automaticamente pelo botão **"Chamar"** no Dashboard, mas pode ser testado diretamente:

```bash
kubectl get svc video-service -n video-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```

### 3. 🐙 ArgoCD (Gestão de Deploy)

```bash
# URL
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Senha (Usuário: admin)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

```

### 4. 📊 Grafana (Monitoramento)

```bash
# URL
kubectl get svc prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Senha (Usuário: admin)
kubectl get secret --namespace monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

```

---

## 📂 Estrutura do Repositório

```text
.
├── .github/workflows/      # Pipelines de CI (Build & Security)
├── argo-applications.yaml  # Manifesto Mestre (GitOps)
├── k8s/
│   ├── core/               # Manifestos do App Principal (Flask)
│   ├── video/              # Manifestos da Telemedicina (Nginx)
├── src/
│   ├── core-app/           # Código Python (Flask + Templates Jinja2)
│   └── video/              # Código Frontend (HTML + Jitsi API)
├── terraform/              # Infraestrutura como Código (AWS)
└── README.md               # Documentação Oficial

```

---

## ⚠️ Troubleshooting (Resolução de Problemas)

* **Erro de "CrashLoopBackOff" no Core App:**
* Verifique se as variáveis de ambiente do RDS (`DB_HOST`, `DB_USER`) foram injetadas corretamente no Pod.
* Confirme se a senha do banco no `app.py` bate com a do Terraform.


* **Site não abre (Timeout):**
* Verifique o **Security Group** dos *Worker Nodes* na AWS. Garanta que há uma regra de entrada liberando **Porta 80** para `0.0.0.0/0`.


* **Câmera/Microfone bloqueados no Vídeo:**
* Como o AWS Academy usa HTTP por padrão, o navegador pode bloquear dispositivos. Clique no ícone de "cadeado/inseguro" na barra de endereço e **permita** o uso de câmera/microfone para o site.


* **Erro de Conexão com Banco (DBeaver):**
* Certifique-se de usar o **Endpoint do RDS** e não o IP interno. O Security Group deve permitir a porta **5432** para o seu IP.