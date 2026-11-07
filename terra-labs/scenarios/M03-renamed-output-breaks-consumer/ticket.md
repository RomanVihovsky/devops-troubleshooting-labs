# Payments' pipeline broke after our network release: "Unsupported attribute"
**INFRA-270** · P1 · Reporter: payments team

Since the network team's release this morning, `terraform plan` of `stacks/payments-api` fails:
`This object does not have an attribute named "subnet_id"` - in the `terraform_remote_state` lookup of
the network stack. The release renamed the output to `app_subnet_id` "for clarity". The payments team is
frozen until Friday and cannot change their code.

Fix it on the network side, keep the new name, and leave a clear signal that the old name is going away.

**Test**: CI plans of both stacks show no changes; the network state exposes both `app_subnet_id` and
`subnet_id` (same value); `stacks/payments-api` is unchanged; the old output is marked as deprecated.
