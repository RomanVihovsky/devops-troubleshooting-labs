state_bucket
sed -i 's/^output "app_subnet_id" {/output "subnet_id" {/' stacks/network/main.tf
apply stacks/network
apply stacks/payments-api
ws_commit "network + payments-api"
sed -i 's/^output "subnet_id" {/output "app_subnet_id" {/' stacks/network/main.tf
ws_commit "network: rename subnet_id -> app_subnet_id (clarity)" "Network team"
apply stacks/network
