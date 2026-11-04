#!/bin/bash
set -euo pipefail

jitconfig=$(curl -fsSL \
  -H "Authorization: Bearer ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "{\"name\":\"${HOSTNAME}\",\"runner_group_id\":1,\"labels\":[\"self-hosted\",\"precommiteu\"]}" \
  "https://api.github.com/repos/${GITHUB_REPO}/actions/runners/generate-jitconfig" \
  | jq -r .encoded_jit_config)
unset GITHUB_PAT
exec /opt/actions-runner/run.sh --jitconfig "$jitconfig"
