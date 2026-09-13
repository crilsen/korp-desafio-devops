#!/bin/bash
# user_data da EC2: baixa e roda o bootstrap do runner (via variáveis de ambiente)
set -euo pipefail

export GITHUB_REPO="${github_repo}"
export GITHUB_TOKEN_PARAMETER_NAME="${github_runner_token_parameter_name}"
export RUNNER_NAME="${runner_name}"
export RUNNER_VERSION="${runner_version}"

install -d -m 0755 /usr/local/lib/korp
cat > /usr/local/lib/korp/bootstrap-runner.sh <<'BOOTSTRAP'
${bootstrap_runner_script}
BOOTSTRAP
chmod 0700 /usr/local/lib/korp/bootstrap-runner.sh
/usr/local/lib/korp/bootstrap-runner.sh
