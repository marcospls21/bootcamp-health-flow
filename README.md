# 🏥 HealthFlow - DevOps & SRE Cloud Lab

O **HealthFlow** é uma plataforma de gestão de saúde digital simulada. Este laboratório foi projetado para demonstrar um ciclo de vida moderno de Engenharia de Software e Cloud, migrando de uma mentalidade legada para **Cloud Native**.

O projeto implementa **Infraestrutura como Código (IaC)**, **GitOps**, **Containerização**, **Orquestração** e **Observabilidade Avançada**, adaptado para rodar nas restrições do **AWS Academy**.

---

## 🏗️ Arquitetura e Componentes

O projeto utiliza uma arquitetura de microsserviços sobre Kubernetes (EKS).

### Stack Tecnológico:

1. **Aplicação (Core):** Python (Flask) servindo interfaces web dinâmicas.
2. **Containerização:** Docker para empacotamento imutável.
3. **Orquestração (AWS EKS):** Cluster Kubernetes gerenciado.
4. **GitOps (ArgoCD):** Controlador que sincroniza o estado do cluster com este repositório Git.
5. **Infraestrutura (Terraform):** Provisiona VPC, EKS, Nodes e Helm Charts.
6. **Observabilidade (Datadog):** Monitoramento de métricas, logs e APM.
7. **CI/CD (GitHub Actions):** Pipeline de Segurança (Trivy), Build e Deploy.

---

## 🚀 Comparativo: Legado vs. Moderno

| Característica | 🐢 Modelo Tradicional (Legado) | 🐇 Modelo HealthFlow (SRE/DevOps) |
| --- | --- | --- |
| **Infraestrutura** | Servidores manuais ("Snowflakes"). | **IaC (Terraform):** Infra descartável e versionada. |
| **Deploy** | Manual (FTP/SSH), alto risco. | **GitOps (ArgoCD):** O Cluster se auto-atualiza via Git. |
| **Escalabilidade** | Limitada ao hardware físico. | **Elástica (Kubernetes):** Pods/Nodes escalam sob demanda. |
| **Monitoramento** | Reativo (espera quebrar). | **Observabilidade (Datadog):** Proativo e centralizado. |
| **Acesso** | VPN ou IP fixo direto na máquina. | **Load Balancer:** Distribuição de tráfego inteligente. |

---

## ⚙️ Guia de Configuração (Passo a Passo)

### 1. Configurar o Repositório Remoto (Git)

Para rodar as Actions na sua conta, aponte para o seu repositório:

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
| `TF_VAR_datadog_api_key` | API Key do Datadog. |

### 3. Ajustar Variáveis do Terraform ⚠️ (CRUCIAL)

#### A. Atualizar ARNs das Roles (main.tf)

Como o AWS Academy muda o ID da conta a cada lab, você deve atualizar as roles.

1. No Console AWS, vá em **IAM > Roles**.
2. Copie o ARN da `LabEksClusterRole` e da `LabEksNodeRole` (nomes com sufixos aleatórios).
3. No arquivo `terraform/main.tf`, atualize o bloco `locals`:
```hcl
locals {
  # ATUALIZE COM SEUS VALORES REAIS
  cluster_role_arn = "arn:aws:iam::SEU_ID:role/LabEksClusterRole-XXXX"
  node_role_arn    = "arn:aws:iam::SEU_ID:role/LabEksNodeRole-XXXX"
}

```



#### B. Atualizar URL do Repositório (variables.tf)

Para o ArgoCD sincronizar com o **seu** código:

1. Abra `terraform/variables.tf`.
2. Altere a variável `repo_url`:
```hcl
variable "repo_url" {
  default = "https://github.com/SEU_USUARIO/NOME_DO_SEU_REPO"
}

```



### 4. Ajustar Imagem Docker (Deployment)

No arquivo `k8s/core/deployment.yaml`, altere a imagem para o seu usuário:

```yaml
image: SEU_USUARIO_DOCKER/health-core:latest

```

---

## 🧪 Executando o Lab

Vá na aba **Actions** do GitHub e dispare o workflow **🧪 Lab Lifecycle**.
Ele fará todo o processo: **Security Scan > Build > Provisionamento Infra > Deploy Apps**.

---

## 🌐 Acessando a Aplicação (HealthFlow)

Após o Terraform finalizar (aprox. 15 min), atualize suas credenciais locais:

```bash
aws eks update-kubeconfig --region us-east-1 --name health-flow-cluster

```

### 🚨 Passo Importante: Liberar Acesso Externo (Security Group)

Para que o LoadBalancer (Link Público) funcione na sua rede doméstica, você deve liberar o Firewall dos nós na AWS. **Sem isso, o site não abrirá.**

1. Acesse o **Console AWS** -> **EC2**.
2. No menu lateral esquerdo, vá em **Security Groups**.
3. Você verá alguns grupos. Procure por um que tenha no nome algo como `eks-cluster-sg-health-flow-cluster`.
* *Dica:* Geralmente é o Security Group que está associado às suas instâncias EC2 (Nodes). Você pode confirmar indo em Instances, clicando em um node e vendo qual Security Group ele usa na aba "Security".


4. Selecione-o e clique na aba inferior **Inbound rules** -> **Edit inbound rules**.
5. Adicione a seguinte regra:
* **Type:** `All traffic` (ou HTTP/HTTPS)
* **Source:** `Anywhere-IPv4` `0.0.0.0/0` (Qualquer lugar).


6. Clique em **Save rules**.

### Opção A: LoadBalancer (Link Público - Recomendado)

Acessível de qualquer lugar. **Consome créditos da AWS.**

1. **Transforme o serviço:**
```bash
kubectl patch svc core-service -n health-core -p '{"spec": {"type": "LoadBalancer"}}'

```


2. **Pegue o Link:**
```bash
kubectl get svc core-service -n health-core --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```


3. **Acesse:** Copie o endereço (ex: `a83...elb.amazonaws.com`) e cole no navegador.
* *Nota:* Pode levar 2-5 minutos para o link funcionar na primeira vez.



### Opção B: Port-Forward (Econômica)

Acessível apenas da sua máquina local. Não precisa alterar Security Group.

```bash
kubectl port-forward svc/core-service -n health-core 9090:80

```

Acesse: [http://localhost:9090](https://www.google.com/search?q=http://localhost:9090)

---

## 🐙 Acessando o ArgoCD (GitOps)

Para visualizar o estado do Cluster:

1. **Senha de Admin:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

```


2. **Acesso (LoadBalancer):**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```


* Acesse via **HTTPS** (aceite o aviso de segurança). Usuário: `admin`.



---

## ⚠️ Troubleshooting

* **Site não abre (Timeout):** Verifique se você realizou o passo de "Liberar Acesso Externo (Security Group)" acima. O firewall da AWS bloqueia conexões externas por padrão.
* **Ping falha no LoadBalancer:** Normal. A AWS bloqueia ICMP (Ping) por padrão. Teste com `curl -Iv URL` ou no navegador.
* **ArgoCD OutOfSync:** Se você alterou algo manualmente, o ArgoCD reclama. Clique em "Sync" para forçar o estado do Git.
* **Erro 403 no Terraform:** Suas credenciais do AWS Academy expiraram. Gere novas no portal.