# "docker build" on manager1 only (simulated with a local tag)
dk tag "$REGISTRY/lab/webapp:1.0" lab/report-api:1.4
deploy_stack
