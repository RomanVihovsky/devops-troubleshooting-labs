sed -i -e 's/?ref=v1.4.0/?ref=v2.0.0/' -e 's/^  name   = /  topic_name = /' stacks/events/main.tf
run_logged "$SETUP_LOG" tf stacks/events init -upgrade -input=false -no-color
run_logged "$SETUP_LOG" tf stacks/events apply -auto-approve -input=false -no-color
