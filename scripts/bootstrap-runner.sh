#!/usr/bin/env bash
#
# Bootstrap do runner self-hosted do GitHub Actions na EC2.
# Instala as deps do deploy (Ansible) e registra o runner como serviço.
#
# Configuração via variáveis de ambiente:
#   GITHUB_REPO     (default: crilsen/korp-desafio-devops)
#   GITHUB_PAT      (obrigatório — token com escopo repo/workflow)
#   RUNNER_NAME     (default: korp-runner)
#   RUNNER_VERSION  (default: 2.337.0)
#   RUNNER_USER     (default: ubuntu)

set -euo pipefail

GITHUB_REPO="${GITHUB_REPO:-crilsen/korp-desafio-devops}"
RUNNER_NAME="${RUNNER_NAME:-korp-runner}"
RUNNER_VERSION="${RUNNER_VERSION:-2.337.0}"
RUNNER_USER="${RUNNER_USER:-ubuntu}"

if [ -z "${GITHUB_PAT:-}" ]; then
  echo "ERRO: defina a variável GITHUB_PAT" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> instalando dependências (ansible, docker-py, rsync)"
apt-get update -y
apt-get install -y ansible-core python3-docker rsync curl

echo "==> instalando collections do Ansible"
ansible-galaxy collection install community.docker ansible.posix

echo "==> baixando o runner v${RUNNER_VERSION}"
mkdir -p "/home/${RUNNER_USER}/actions-runner"
cd "/home/${RUNNER_USER}/actions-runner"
curl -sL -o runner.tar.gz \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
tar xzf runner.tar.gz
rm -f runner.tar.gz

echo "==> pegando token de registro"
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_REPO}/actions/runners/registration-token" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')

chown -R "${RUNNER_USER}:${RUNNER_USER}" "/home/${RUNNER_USER}/actions-runner"

echo "==> registrando o runner"
su - "${RUNNER_USER}" -c \
  "cd /home/${RUNNER_USER}/actions-runner && ./config.sh --url https://github.com/${GITHUB_REPO} --token ${REG_TOKEN} --name ${RUNNER_NAME} --labels self-hosted --unattended --work _work"

echo "==> instalando como serviço e iniciando"
cd "/home/${RUNNER_USER}/actions-runner"
./svc.sh install "${RUNNER_USER}"
./svc.sh start

echo "==> runner pronto"
