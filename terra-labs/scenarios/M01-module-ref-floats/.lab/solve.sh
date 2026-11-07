sed -i 's/?ref=main/?ref=v1.2.0/' stacks/storefront/main.tf
run_logged "$SETUP_LOG" tf stacks/storefront init -upgrade -input=false -no-color
