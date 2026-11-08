#!/bin/sh
# deploy + smoke test (the CI runner is the controller)
set -eu
mkdir -p .ci
ansible-playbook deploy.yml | tee .ci/deploy.log
TOKEN=$(sed -n 's/.*"msg": "SMOKE_TOKEN=\(.*\)"$/\1/p' .ci/deploy.log)
curl -fsS --max-time 5 -H "X-Api-Token: $TOKEN" http://web1/api/health
echo "smoke test passed"
