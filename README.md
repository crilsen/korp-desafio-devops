# Korp DevOps Challenge

Serviço HTTP em Go empacotado em container, exposto atrás de um
proxy reverso NGINX, monitorado com Prometheus + Grafana + Loki e provisionado de
forma automatizada com Ansible e Terraform.

O projeto pode ser executado localmente para demonstração e desenvolvimento, ou na
AWS para uma implantação completa. Na AWS, o provisionamento e o deploy podem ser
feitos manualmente com Terraform e Ansible ou automaticamente pelo GitHub Actions.

## Arquitetura

```
                    ┌─────────────────────────────────────────────┐
   Internet ──►     │  Cloudflare (proxied, HTTPS na borda)        │
                    └──────────────┬──────────────────────────────┘
                                   │ 80
                    ┌──────────────▼──────────────────────────────┐
                    │  NGINX (proxy reverso, roteamento por host)  │
                    │  korp-app        -> http-server:8080         │
                    │  korp-grafana    -> grafana:3000             │
                    │  korp-prometheus -> prometheus:9090          │
                    └─────────────────────────────────────────────┘
                                   │ rede interna (bridge)
        ┌──────────────┬───────────┼───────────┬──────────────────┐
        │              │           │           │                  │
   http-server    prometheus    grafana     loki              alloy
   (Go, :8080)    (:9090)      (:3000)     (:3100)          (logs -> loki)
                                   │
                              node-exporter
                              (CPU/mem/disco)
```

## Stack

| Componente | Papel |
|---|---|
| **http-server** (Go) | API `GET /projeto-korp` + métricas em `/metrics` |
| **NGINX** | Proxy reverso, roteia por `server_name` na porta 80 |
| **Prometheus** | Coleta de métricas (serviço + host via node-exporter) |
| **Grafana** | Dashboards provisionados por arquivo |
| **Loki + Alloy** | Agregação e coleta de logs dos containers, via proxy com API Docker limitada |
| **Ansible** | Provisiona o ambiente inteiro com um único comando |
| **Terraform** | IaC: subnet, rota, SG, key pair, EC2 e EIP em VPC existente |
| **GitHub Actions** | CI (teste/build) e CD (deploy) |

## Estrutura

```
http-server/     serviço Go + Dockerfile (multi-stage)
nginx/           configs do proxy reverso
monitoring/      prometheus.yml, loki, promtail, grafana (provisioning + dashboard)
ansible/         playbook + inventário
terraform/       subnet, rota, SG, EC2, keypair e EIP; usa VPC existente
scripts/         instalação de dependências
.github/         CI/CD
```

## Como rodar

### Modos de execução

- **Local:** sobe toda a stack com Docker Compose na máquina do desenvolvedor. É o
  caminho mais rápido para testar a aplicação, observabilidade e proxy reverso.
- **AWS:** o Terraform prepara a infraestrutura dentro de uma VPC existente; o
  Ansible instala Docker, sincroniza o projeto e inicia a stack na EC2.
- **Automatizado:** após a infraestrutura e o runner self-hosted estarem prontos,
  um push na `main` aciona o CD, que publica a imagem Docker e executa o deploy com
  Ansible na própria EC2.

### Pré-requisitos

- Docker + Docker Compose v2
- Ansible (para o provisionamento remoto)
- Terraform (para a infra na AWS)

### 1. Local (só o ambiente)

```bash
cp .env.example .env
# Edite .env e defina uma senha forte para o Grafana.
docker compose up -d --build
curl http://localhost:80/projeto-korp
```

### 2. Infra na AWS (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # substitua os placeholders conforme necessário
terraform init
terraform apply
```

Informe somente o `vpc_id` de uma VPC existente no `terraform.tfvars`. O Terraform
cria a subnet pública e sua tabela de rotas nessa VPC, usando o Internet Gateway já
associado a ela; ele não cria nem altera a VPC ou o Internet Gateway.

### 3. Provisionamento completo dentro do SO (Ansible)

```bash
ansible-playbook -i ansible/inventory.producao.ini ansible/playbook.yml \
  -e "ansible_host=<IP>" \
  -e "ansible_user=ubuntu" \
  -e "ansible_ssh_private_key_file=<caminho>.pem"
```

## CI/CD

Os workflows estão em [`.github/workflows/`](.github/workflows/).

### CI

O workflow de CI roda em pull requests e em pushes para `main` e `dev`. Ele:

- executa `go vet` e os testes do serviço Go;
- valida a configuração do Docker Compose;
- constrói a imagem do serviço para confirmar que o Dockerfile está funcional;
- valida a sintaxe e executa o lint do playbook Ansible.

### CD

O workflow de CD é disparado a cada push na `main` e possui duas etapas:

1. **Build e publicação:** constrói a imagem da aplicação e a publica no GitHub
   Container Registry (GHCR), identificada pelo SHA do commit.
2. **Deploy automatizado:** executa no runner self-hosted da EC2. O workflow gera
   temporariamente o `.env` e o arquivo de autenticação do Prometheus a partir dos
   GitHub Secrets e chama o playbook Ansible para atualizar a stack.

O deploy atual reconstrói a aplicação a partir do checkout sincronizado pelo Ansible.
A imagem publicada no GHCR também fica disponível como artefato versionado e pode ser
usada como alternativa em um fluxo de deploy baseado em `image:` no Docker Compose.

Para o CD, configure no repositório os secrets `GRAFANA_ADMIN_PASSWORD` e
`PROMETHEUS_PASSWORD`. O token de registro do runner permanece no AWS SSM Parameter
Store como `SecureString`, acessado pela role da EC2.

## Endpoints

- App: `GET /projeto-korp` → `{"nome":"Projeto Korp","horario":"<UTC>"}`
- Métricas: `/metrics` (formato Prometheus)

## Logs (Loki + Alloy)

A pilha de logs é centralizada no **Loki** e coletada pelo **Alloy**:

- **Loki** (`grafana/loki:3.7.7`) — agregação e armazenamento dos logs (TSDB no
  S3 `cn-korp-loki-logs-us-east-1`, modo single-binary). Recebe os logs via API push
  na porta `3100`; a role da EC2 permite esse acesso sem chaves estáticas.
- **Alloy** (`grafana/alloy:v1.12.1`) — agente que descobre os containers por um
  proxy com permissões Docker limitadas e envia os logs pro Loki, adicionando o label
  `container`. O cursor de leitura é persistido no volume `alloy-data`.
- **Serviço Go** — registra cada requisição (`GET /projeto-korp <duração>`) via
  middleware, que sai no stdout e vira log no Docker.
- **Grafana** — datasource Loki provisionado (`uid: loki`) e painel
  **"Logs do serviço"** no dashboard, consultando
  `{container=~"http-server-projeto-korp|nginx"}`.

Com isso o Grafana fecha a tríade de observabilidade: **métricas** (Prometheus) +
**logs** (Loki) num só lugar.

> **Nota:** o Alloy é o coletor ativo e substitui o Promtail, que está em modo de manutenção.

## Notas

- Segredos (senha do Grafana, basic auth do Prometheus, chaves, IPs reais) **não**
  vão pro repositório — ficam em arquivos ignorados pelo `.gitignore`
  (`.env`, `*.pem`, `*.tfvars`, inventários de produção, etc.). Use
  `.env.example` como modelo e nunca envie o `.env` preenchido.
- Os dados operacionais do Grafana e do Prometheus persistem nos volumes
  `grafana-data` e `prometheus-data`; as configurações e dashboards continuam
  versionados nos diretórios `monitoring/` e `nginx/`.
- O dashboard e o datasource do Grafana são provisionados automaticamente por
  arquivo, sem configuração manual.
- O token do runner self-hosted deve ficar em um parâmetro **SecureString** no AWS SSM.
  O Terraform recebe somente o nome e o ARN do parâmetro; a instância o lê com uma role
  de menor privilégio durante o bootstrap.
