#!/bin/bash
# user_data da EC2: baixa e roda o bootstrap do runner (via variáveis de ambiente)
set -euo pipefail

export GITHUB_REPO="${github_repo}"
export GITHUB_PAT="${github_pat}"
export RUNNER_NAME="${runner_name}"
export RUNNER_VERSION="${runner_version}"

curl -sL "https://raw.githubusercontent.com/${github_repo}/main/scripts/bootstrap-runner.sh" | bash
