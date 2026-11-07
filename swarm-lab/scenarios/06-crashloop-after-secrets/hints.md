## Hint 1
This one leaves logs: `docker service logs app_web` (add `--raw` / `-f`).
## Hint 2
Where does the app look for the password, and where does swarm actually mount the
secret? `docker service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' app_web`
## Hint 3
Short syntax `secrets: [redis_pw]` mounts the file at `/run/secrets/<secret name>`.
Use the long syntax with `target:` or point the app at the real path.
