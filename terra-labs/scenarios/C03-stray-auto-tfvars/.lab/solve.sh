git rm -q stacks/web-config/local-test.auto.tfvars
printf '# local experiments never reach CI\n*.auto.tfvars\n' > stacks/web-config/.gitignore
apply stacks/web-config
