# Config change cannot be deployed
**SWARM-108** · Priority P3 · Change request CR-4711

Marketing wants the greeting changed from **Hello** to **Welcome**. The greeting
lives in `greeting.txt`, delivered to the containers as a swarm **config**.
A colleague already edited `workspace/greeting.txt`, but every deploy fails:

```
$ docker stack deploy -c /lab/workspace/stack.yml app
failed to update config app_greeting: Error response from daemon: rpc error:
code = InvalidArgument desc = only updates to Labels are allowed
```

**Done when**
- http://172.30.0.{11,21,22}:8080 answer `Welcome from ...`
- done with a normal rolling update (the stack keeps running)
