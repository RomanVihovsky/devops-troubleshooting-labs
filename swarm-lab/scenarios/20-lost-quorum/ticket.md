# Two managers lost - the swarm is headless
**SWARM-120** · Priority P0 · Reporter: incident commander

We ran 3 managers (manager1-3). Tonight the storage under **manager2 and manager3**
died. Both VMs were re-provisioned **from scratch** (same names and IPs, fresh
Docker, not part of any swarm). manager1 survived. Since then on manager1:

```
$ docker node ls
Error response from daemon: rpc error: code = Unknown desc = The swarm does not
have a leader. It's possible that too few managers are online. ...
```

Running containers still serve traffic, but nothing can be deployed or scaled.

**Done when**
- the swarm has **3 healthy managers** (1 Leader + 2 Reachable), no `Down` nodes
- the existing `app_web` service survived (same service, **not** re-created)
- http://172.30.0.{11,21,22}:8080 answer
