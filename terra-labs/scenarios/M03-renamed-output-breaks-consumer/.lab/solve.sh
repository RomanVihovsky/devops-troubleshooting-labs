cat >> stacks/network/main.tf <<'TF'

# Kept for consumers of the old name (payments-api). Root outputs cannot use `deprecated = ...`
# (that only works for module outputs), so we say it in the description and the changelog.
output "subnet_id" {
  description = "DEPRECATED: use app_subnet_id. Will be removed after 2026-12-31."
  value       = aws_subnet.app.id
}
TF
apply stacks/network
