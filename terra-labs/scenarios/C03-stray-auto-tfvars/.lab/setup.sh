state_bucket
apply stacks/web-config
ws_commit "web-config: staging"
printf '# local testing - DO NOT COMMIT\nenv   = "prod"\ndebug = true\n' > stacks/web-config/local-test.auto.tfvars
ws_commit "wip: debug logging" "Chris (web)"
apply stacks/web-config     # this morning's deploy
