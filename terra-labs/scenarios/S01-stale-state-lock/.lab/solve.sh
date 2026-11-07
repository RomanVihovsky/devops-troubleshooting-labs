tf stacks/payments init -input=false -no-color >/dev/null
tf stacks/payments force-unlock -force "$(recall lock_id)"
