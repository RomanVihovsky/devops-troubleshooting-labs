sed -i 's|    name = "tfl-jobs-net"|    name = docker_network.jobs.name|' stacks/worker/main.tf
apply stacks/worker
