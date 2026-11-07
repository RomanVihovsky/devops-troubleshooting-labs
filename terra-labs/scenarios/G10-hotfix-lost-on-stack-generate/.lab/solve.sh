sed -i 's/    replicas = 2/    replicas = 4 # INC-902/' live/prod/terragrunt.stack.hcl
(cd live/prod && terragrunt stack run --non-interactive --log-level error -- apply -auto-approve -input=false -no-color) >> "$SETUP_LOG" 2>&1
