(cd live/prod && terragrunt stack generate --log-level error) >> "$SETUP_LOG" 2>&1
(cd live/prod && terragrunt stack run --non-interactive --log-level error --backend-bootstrap -- apply -auto-approve -input=false -no-color) >> "$SETUP_LOG" 2>&1
# INC-902, 02:40 - the hotfix
sed -i 's/^replicas = 2/replicas = 4/' live/prod/.terragrunt-stack/web/terragrunt.values.hcl
run_logged "$SETUP_LOG" tg live/prod/.terragrunt-stack/web apply -auto-approve -input=false -no-color
# 05:00 - nightly
(cd live/prod && terragrunt stack run --non-interactive --log-level error -- apply -auto-approve -input=false -no-color) >> "$SETUP_LOG" 2>&1
