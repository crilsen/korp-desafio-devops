#!/usr/bin/env bash
#
# Instala Docker Engine + plugin do Compose numa máquina Linux.
# Feito pra Ubuntu/Debian (mesma base que o playbook Ansible usa).
# Uso: sudo ./scripts/install-docker.sh
#
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "rode como root: sudo $0" >&2
  exit 1
fi

# instala os pacotes básicos necessários pro repositório do Docker
apt-get update
apt-get install -y ca-certificates curl gnupg

# adiciona a chave GPG oficial e o repositório
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list >/dev/null

# instala o Docker e o plugin do Compose
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# deixa o daemon ativo e rodando
systemctl enable --now docker

# permite rodar docker sem sudo (opcional, mas ajuda no dia a dia)
if [ -n "${SUDO_USER:-}" ]; then
  usermod -aG docker "$SUDO_USER"
  echo "usuário '$SUDO_USER' adicionado ao grupo docker (reinicie a sessão pra valer)"
fi

echo "Docker instalado: $(docker --version)"
echo "Compose instalado: $(docker compose version)"
