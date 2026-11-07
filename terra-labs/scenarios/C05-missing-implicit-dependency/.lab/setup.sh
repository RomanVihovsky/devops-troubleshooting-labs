run_logged "$SETUP_LOG" tf stacks/worker init -input=false -no-color
run_logged "$SETUP_LOG" tf stacks/worker apply -auto-approve -input=false -no-color -target=docker_network.jobs
apply stacks/worker
for w in mail pdf thumbs; do remember_ctr "tfl-worker-$w"; done
