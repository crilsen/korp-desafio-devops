# korp-desafio-devops

Desafio DevOps: serviço HTTP em Go empacotado em container, exposto atrás de um
proxy reverso NGINX, monitorado com Prometheus + Grafana + Loki e provisionado de
forma automatizada com Ansible e Terraform.

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
   http-server    prometheus    grafana     loki             promtail
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
| **Loki + Promtail** | Agregação e coleta de logs dos containers |
| **Ansible** | Provisiona o ambiente inteiro com um único comando |
| **Terraform** | IaC: VPC, subnet, RT, SG, key pair, EC2 e EIP |
| **GitHub Actions** | CI (teste/build) e CD (deploy) |

## Estrutura

```
http-server/     serviço Go + Dockerfile (multi-stage)
nginx/           configs do proxy reverso
monitoring/      prometheus.yml, loki, promtail, grafana (provisioning + dashboard)
ansible/         playbook + inventário
terraform/       VPC, subnet, rt, sg, ec2, keypair, eip
scripts/         instalação de dependências
.github/         CI/CD
```

## Como rodar

### Pré-requisitos

- Docker + Docker Compose v2
- Ansible (para o provisionamento remoto)
- Terraform (para a infra na AWS)

### 1. Local (só o ambiente)

```bash
docker compose up -d --build
curl http://localhost:80/projeto-korp
```

### 2. Infra na AWS (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # está em placeholderts, substitua conforme necessário
terraform init
terraform apply
```

### 3. Provisionamento completo dentro do SO (Ansible)

```bash
ansible-playbook -i ansible/inventory.producao.ini ansible/playbook.yml \
  -e "ansible_host=<IP>" \
  -e "ansible_user=ubuntu" \
  -e "ansible_ssh_private_key_file=<caminho>.pem"
```

## Endpoints

- App: `GET /projeto-korp` → `{"nome":"Projeto Korp","horario":"<UTC>"}`
- Métricas: `/metrics` (formato Prometheus)

## Logs (Loki + Promtail)

A pilha de logs é centralizada no **Loki** e coletada pelo **Promtail**:

- **Loki** (`grafana/loki:3.7.7`) — agregação e armazenamento dos logs (TSDB em
  filesystem, modo single-binary). Recebe os logs via API push na porta `3100`.
- **Promtail** (`grafana/promtail:3.6.11`) — agente que descobre os containers via
  `docker_sd` (socket do Docker) e envia os logs pro Loki, adicionando o label
  `container`.
- **Serviço Go** — registra cada requisição (`GET /projeto-korp <duração>`) via
  middleware, que sai no stdout e vira log no Docker.
- **Grafana** — datasource Loki provisionado (`uid: loki`) e painel
  **"Logs do serviço"** no dashboard, consultando
  `{container=~"http-server-projeto-korp|nginx"}`.

Com isso o Grafana fecha a tríade de observabilidade: **métricas** (Prometheus) +
**logs** (Loki) num só lugar.

> **Nota:** o Promtail entrou em modo de manutenção — o substituto oficial da
> Grafana Labs é o **Alloy** (antigo Grafana Agent). Usei Promtail por simplicidade
> e familiaridade, mas trocar pelo Alloy é uma evolução natural.

## Notas

- Segredos (senha do Grafana, basic auth do Prometheus, chaves, IPs reais) **não**
  vão pro repositório — ficam em arquivos ignorados pelo `.gitignore`
  (`.env`, `*.pem`, `terraform.tfvars`, etc.).
- O dashboard e o datasource do Grafana são provisionados automaticamente por
  arquivo, sem configuração manual.
