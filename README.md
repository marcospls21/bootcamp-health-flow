Com certeza! Abaixo está o **README.md** atualizado.

Fiz as seguintes alterações para refletir a nova estrutura:

1. **Componentes:** Adicionei o serviço de "Apresentação" na lista.
2. **Estrutura de Pastas:** Atualizei a árvore de diretórios para incluir `src/apresentacao` e `k8s/apresentacao`.
3. **Configuração do ArgoCD:** Adicionei a seção explicando como subir as duas aplicações de uma vez (Padrão *App of Apps*).
4. **Acesso:** Criei uma seção dedicada para pegar o link da Apresentação.

---

# 🏥 HealthFlow - DevOps & SRE Cloud Lab

O **HealthFlow** é uma plataforma de gestão de saúde digital simulada. Este laboratório demonstra um ciclo de vida moderno de Engenharia de Software e Cloud, migrando de uma mentalidade legada para **Cloud Native**.

O projeto implementa **Infraestrutura como Código (IaC)**, **GitOps**, **Containerização**, **Orquestração** e **Observabilidade Avançada**, rodando nas restrições do **AWS Academy**.

---

## 🏗️ Arquitetura e Componentes

O projeto utiliza uma arquitetura de microsserviços sobre Kubernetes (EKS).

### Microserviços:

1. **Core App:** Aplicação principal em Python (Flask) para gestão de pacientes.
2. **Apresentação:** Aplicação Nginx servindo o deck executivo e vídeo de demonstração do projeto.

### Infraestrutura & Ferramentas:

* **Orquestração:** AWS EKS (Kubernetes).
* **GitOps:** ArgoCD sincronizando o estado do cluster com este repositório.
* **IaC:** Terraform provisionando VPC, EKS, Nodes e Helm Charts.
* **Observabilidade:** Datadog (Métricas, Logs e APM).
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
| `TF_VAR_datadog_api_key` | API Key do Datadog. |

### 3. Ajustar Variáveis do Terraform

* **`terraform/main.tf`**: Atualize os ARNs das Roles (`LabEksClusterRole` e `LabEksNodeRole`).
* **`terraform/variables.tf`**: Atualize a `repo_url` para o seu GitHub.

### 4. Ajustar Imagens Docker (Manifestos)

Nos arquivos `k8s/core/deployment.yaml` e `k8s/apresentacao/deployment.yaml`, altere a imagem para o seu usuário:

```yaml
image: SEU_USUARIO_DOCKER/health-core:latest
# e
image: SEU_USUARIO_DOCKER/health-apresentacao:latest

```

---

## 🚀 Executando o Lab (Deploy)

1. Vá na aba **Actions** do GitHub e dispare o workflow **🧪 Lab Lifecycle**.
2. Aguarde o pipeline finalizar (Build das imagens + Terraform Apply).
3. Atualize suas credenciais locais:
```bash
aws eks update-kubeconfig --region us-east-1 --name health-flow-cluster

```



---

## 🐙 Configurando o GitOps (ArgoCD)

Para subir todas as aplicações (Core e Apresentação) de uma vez:

1. Garanta que o arquivo `argo-applications.yaml` na raiz está apontando para o seu repositório.
2. Aplique o manifesto mestre:
```bash
kubectl apply -f argo-applications.yaml

```


3. O ArgoCD detectará as pastas `k8s/core` e `k8s/apresentacao` e fará o deploy automático.

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

*Copie a URL e acesse no navegador.*

### 2. Aplicação Apresentação (Slides & Vídeo)

Acesse a apresentação executiva e o vídeo de demonstração:

```bash
kubectl get svc apresentacao-service -n health-core --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```

*Copie a URL e acesse no navegador.*

### 3. Painel do ArgoCD

Para ver o estado do GitOps e sincronização:

```bash
# Pegar senha
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Pegar URL (Se tiver criado LoadBalancer para ele)
kubectl get svc argocd-server -n argocd --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'

```

---

## 📂 Estrutura do Projeto

```text
.
├── .github/workflows/
│   └── lab-lifecycle.yml  # Pipeline (Security > Build > Deploy)
├── argo-applications.yaml # Manifesto "App of Apps" do ArgoCD
├── k8s/
│   ├── core/              # Manifestos do App Core
│   └── apresentacao/      # Manifestos da Apresentação [NOVO]
├── src/
│   ├── core-app/          # Código Python (Flask)
│   └── apresentacao/      # Código HTML/Vídeo + Dockerfile [NOVO]
├── terraform/             # Código IaC (EKS, VPC, Helm)
└── README.md              # Documentação

```

---

## ⚠️ Troubleshooting

* **Apresentação sem vídeo:** Verifique se o arquivo `video.mp4` está na pasta `src/apresentacao` antes do commit. O Dockerfile precisa da instrução `COPY` correta.
* **Site não abre (Timeout):** Verifique o **Security Group** dos Worker Nodes no Console EC2. Garanta que há uma regra de entrada liberando tráfego de `0.0.0.0/0`.
* **Erro 403 no Terraform:** Suas credenciais do AWS Academy expiraram. Gere novas no portal e atualize as Secrets do GitHub.