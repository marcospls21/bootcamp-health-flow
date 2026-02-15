# 🏥 HealthFlow - Plataforma de Telemedicina & Gestão Hospitalar (DevOps/SRE Lab)

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

## 📋 Sobre o Projeto

O **HealthFlow** é uma solução completa de infraestrutura moderna simulando um ambiente real de HealthTech. O projeto demonstra a migração de aplicações para **Microserviços**, orquestração com **Kubernetes (EKS)**, pipeline de **CI/CD** e práticas de **SRE (Site Reliability Engineering)**.

A plataforma consiste em:
1.  **Core App (Dashboard):** Gestão de pacientes, médicos e agendamentos (Python/Flask + PostgreSQL RDS).
2.  **Video App (Telemedicina):** Sala de conferência segura e criptografada via WebRTC (Jitsi API + Nginx Alpine).

---

## 🏗️ Arquitetura e Tecnologias

O projeto foi construído seguindo os pilares do **Well-Architected Framework**:

* **Cloud Provider:** AWS (VPC, EKS, RDS, Load Balancers).
* **IaC (Infra as Code):** Terraform modularizado.
* **Containerização:** Docker (Imagens otimizadas Alpine).
* **Orquestração:** Kubernetes (Deployments, Services, Ingress).
* **GitOps & CI/CD:** GitHub Actions (Build & Push) + ArgoCD (Sync).
* **Banco de Dados:** PostgreSQL (Gerenciado via AWS RDS).

---

## 🚀 Melhorias e Fixes Implementados (SRE Log)

Durante o desenvolvimento, diversos desafios de infraestrutura foram superados:

### 1. Aplicação de Vídeo (Telemedicina Real-Time)
* **Problema:** A versão antiga era estática.
* **Solução:** Reescrita total do Frontend (`src/video-app`) integrando a API **WebRTC do Jitsi Meet**.
* **Security Fix:** Implementação de tratamento para bloqueios de navegador (Chrome/Edge) em ambientes HTTP (AWS LoadBalancer), forçando flags de origem insegura ou tunelamento via `localhost`.

### 2. Banco de Dados e Persistência
* **Problema:** Erro `Relation does not exist` e `Connection Refused` nos Pods.
* **Solução:** * Criação de script SQL robusto para inicialização de tabelas (`consultas`, `usuarios`) com cláusulas `IF NOT EXISTS`.
    * Implementação de lógica de `Retry` e variáveis de ambiente no Python para conexão resiliente com o RDS.

### 3. Terraform Deadlock (Destruição)
* **Problema:** O `terraform destroy` falhava com `DependencyViolation` porque o Kubernetes criava LoadBalancers que o Terraform desconhecia.
* **Solução (Automação):** Criação de um script de **"Cleanup Pré-Destroy"** no Pipeline.
    * O script conecta no cluster EKS antes da destruição.
    * Remove forçadamente todos os `Service type: LoadBalancer`.
    * Aguarda a liberação das ENIs (Interfaces de Rede) pela AWS.
    * Executa o `terraform destroy` limpo.

---

## 📦 Estrutura do Projeto

```bash
.
├── .github/workflows    # Pipelines de CI/CD (Build e Destroy)
├── k8s                  # Manifestos Kubernetes (Deployment, Service)
│   ├── core             # Aplicação Python (Dashboard)
│   └── video            # Aplicação Nginx (Telemedicina)
├── src                  # Código Fonte
│   ├── core-app         # Backend Flask + Conectores DB
│   └── video-app        # Frontend SPA + Dockerfile Alpine
├── terraform            # Infraestrutura como Código (EKS, VPC, RDS)
└── destroy.sh           # Script SRE de limpeza de recursos órfãos

```

---

## 🛠️ Como Executar

### Pré-requisitos

* Conta AWS ativa.
* Docker, Kubectl e Terraform instalados.

### 1. Provisionando a Infra (Terraform)

```bash
cd terraform
terraform init
terraform apply -auto-approve

```

### 2. Configurando o Banco de Dados

Conecte-se ao RDS criado (via DBeaver ou PgAdmin) e execute o script de inicialização localizado em `src/core-app/init.sql` para criar as tabelas `usuarios` e `consultas`.

### 3. Deploy das Aplicações (ArgoCD ou Manual)

```bash
# Aplica os manifestos
kubectl apply -f k8s/core/
kubectl apply -f k8s/video/

```

### 4. Acessando a Telemedicina (Fix de Navegador)

Como o LoadBalancer da AWS Academy é HTTP, habilite a flag de segurança no Chrome para testar a câmera:

1. Acesse `chrome://flags/#unsafely-treat-insecure-origin-as-secure`
2. Adicione a URL do seu LoadBalancer.
3. Clique em "Enabled" e reinicie o navegador.

---

## 🧹 Destruição do Ambiente (Importante)

Para evitar custos e erros de dependência, utilize o script automatizado que limpa os Load Balancers antes de destruir a VPC:

```bash
chmod +x destroy.sh
./destroy.sh

```

---

## 👨‍💻 Autor

**Marcos** - *DevOps & SRE Engineer*
Projeto desenvolvido como parte do Bootcamp de Engenharia de Confiabilidade.

```

```