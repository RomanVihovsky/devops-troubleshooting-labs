## Hint 1
Try it yourself: `./lab deploy`. Then look at `docker config ls` and
`docker config inspect --pretty app_greeting`.
## Hint 2
Swarm configs and secrets are **immutable** - their content can never change.
So how do you "change" one? You create a new one and point the service at it.
## Hint 3
In the stack file, give the config a new object name, e.g.
`configs: greeting: { name: app_greeting_v2, file: ./greeting.txt }`, then deploy.
