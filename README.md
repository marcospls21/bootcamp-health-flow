# 🏥 HealthFlow - Ecossistema de Telemedicina & Gestão Hospitalar (SRE Edition)

Este repositório contém a implementação completa de uma infraestrutura escalável, resiliente e automatizada para a plataforma **HealthFlow**. O projeto demonstra a aplicação prática de conceitos de **Cloud Architecture**, **GitOps**, **Observabilidade** e **Automated Infrastructure**.

## 📑 Sumário
1. [Visão Geral e Arquitetura](#-visão-geral-e-arquitetura)
2. [O que foi construído (Stack Tecnológica)](#-o-que-foi-construído)
3. [⚙️ Preparação e Ajustes de Código (Fork & Customize)](#️-preparação-e-ajustes-de-código-fork--customize)
4. [🔐 Configuração de Secrets (GitHub Actions)](#-configuração-de-secrets-github-actions)
5. [🚀 Guia de Implantação Passo a Passo](#-guia-de-implantação-passo-a-passo)
6. [🔧 Engenharia de Software: Ajustes e Melhorias](#-engenharia-de-software-ajustes-e-melhorias)
7. [📋 Guia de Operação e Validação](#-guia-de-operação-e-validação)
8. [🕵️ Troubleshooting & SRE (Lições Aprendidas)](#-troubleshooting--sre-lições-aprendidas)
9. [💣 Ciclo de Vida: Destruição Segura](#-ciclo-de-vida-destruição-segura)

---

## 🏛️ Visão Geral e Arquitetura

O HealthFlow foi migrado de uma estrutura legada para um modelo de microserviços rodando em **Amazon EKS (Elastic Kubernetes Service)**. A solução separa as responsabilidades de negócio em duas frentes:

* **Microserviço Core (Backend):** Gestão de dados críticos e lógica de agendamento.
* **Microserviço Video (Telemedicina):** Comunicação em tempo real via WebRTC.

A persistência de dados utiliza o **AWS RDS (PostgreSQL)**, garantindo que o estado da aplicação seja independente da vida útil dos containers no cluster.

---

## ⚙️ Preparação e Ajustes de Código (Fork & Customize)

Se você fez um Fork deste repositório, você precisa ajustar as referências para os **seus** repositórios de imagem, caso contrário, o Kubernetes tentará baixar as imagens do autor original.

### 1. Ajuste nos Manifestos Kubernetes (`/k8s`)
Nos arquivos `k8s/core/deployment.yaml` e `k8s/video/deployment.yaml`, localize o campo `image:` e substitua pelo seu usuário do Docker Hub:
* De: `marcos/health-core:latest`
* Para: `seu-usuario-docker/health-core:latest`

### 2. Ajuste no Workflow de CI/CD (`/.github/workflows`)
No arquivo de pipeline (ex: `ci.yml` ou `cd.yml`), ajuste as variáveis de nome de imagem para apontar para o seu repositório pessoal no Docker Hub.

---

## 🔐 Configuração de Secrets (GitHub Actions)

Para que o pipeline consiga compilar as imagens e destruir a infraestrutura automaticamente, você deve configurar as seguintes **Secrets** no seu repositório do GitHub (**Settings > Secrets and variables > Actions**):

| Secret Name | Descrição |
| :--- | :--- |
| `AWS_ACCESS_KEY_ID` | Sua chave de acesso AWS (fornecida no AWS Details/Credentials) |
| `AWS_SECRET_ACCESS_KEY` | Sua chave secreta AWS |
| `AWS_SESSION_TOKEN` | (Obrigatório se usar AWS Academy) O token temporário da sessão |
| `DOCKER_USERNAME` | Seu usuário do Docker Hub |
| `DOCKER_PASSWORD` | Seu Access Token ou Senha do Docker Hub |

---

## 🚀 Guia de Implantação Passo a Passo

### 1. Preparação do Ambiente
Certifique-se de ter o AWS CLI configurado com as credenciais da AWS Academy (ou conta pessoal).

### 2. Provisionamento via Terraform
```bash
cd terraform
terraform init
terraform apply -auto-approve

```

*Aguarde a saída dos endpoints do cluster e do RDS no terminal.*

### 3. Conexão com o Cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name health-cluster

```

### 4. Inicialização do Banco de Dados (Passo Crucial)

A aplicação não iniciará corretamente se o esquema do banco não existir.

1. Obtenha o Endpoint do RDS (saída do Terraform).
2. Use o DBeaver ou PgAdmin para conectar ao banco `healthflowdb`.
3. Execute o script `src/core-app/init.sql`. **Este script cria as tabelas `usuarios` e `consultas` e insere o acesso Admin inicial.**

---

## 🔧 Engenharia de Software: Ajustes e Melhorias

* **Refatoração do Video-App:** Integrada a API do Jitsi Meet para fornecer vídeo HD e chat via WebRTC.
* **Resiliência de Conexão:** Backend Flask configurado com lógica de `Retry` para aguardar o banco RDS estar disponível, evitando CrashLoopBackOff.
* **Limpeza de Código:** Removidos imports obsoletos e variáveis não utilizadas para manter o código limpo e performático.

---

## 📋 Guia de Operação e Validação

### Como pegar os acessos (Load Balancers)

Rode o comando: `kubectl get svc -A`.

* O link do **Dashboard** estará em `core-service` (External IP).
* O link da **Telemedicina** estará em `video-service` (External IP).

### Credenciais Padrão (Criadas no init.sql)

* **Login Admin:** `admin@healthflow.com`
* **Senha:** `123`

### Validação da Telemedicina

Para testar a câmera em conexões HTTP:

1. Acesse `chrome://flags/#unsafely-treat-insecure-origin-as-secure`.
2. Insira o endereço do Load Balancer do Video-App e marque como **Enabled**.

---

## 🕵️ Troubleshooting & SRE (Lições Aprendidas)

* **Erro 500 no Dashboard:** Geralmente causado pela falta das tabelas no RDS. Execute o `init.sql`.
* **ErrImagePull:** Verifique se você atualizou o nome da imagem no `deployment.yaml` para o seu usuário do Docker Hub e se o repositório é público.
* **DependencyViolation no Terraform:** Ocorre quando o LoadBalancer do Kubernetes ainda está ativo ao tentar deletar a VPC. Use o script `destroy.sh`.

---

**O que o script faz:**

1. Conecta ao EKS e deleta todos os `Services` do tipo LoadBalancer.
2. Aguardas 60 segundos para a AWS desalocar as interfaces de rede.
3. Executa o `terraform destroy` de forma limpa.

---

**Autor:** Marcos (SRE/DevOps Engineer)

```