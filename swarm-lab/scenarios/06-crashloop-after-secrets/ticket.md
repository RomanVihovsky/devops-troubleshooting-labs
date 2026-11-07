# Crash loop after moving the redis password to a secret
**SWARM-106** · Priority P1 · Reporter: security champion

We moved the redis password from an env var into a Docker secret (finally!).
Redis came up fine with the secret. The `web` service now crash-loops: tasks go
`Running` -> `Failed` every few seconds with `non-zero exit (1)`.

**Done when**
- `app_web` is 2/2 and stable
- the password still comes from the secret
- http://172.30.0.{11,21,22}:8080 answer with a `hits=` counter
