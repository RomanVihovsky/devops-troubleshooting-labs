# Login banner on every node shows raw template code
**OPS-281** · P3 · Reporter: on-call

After the runner upgrade (ansible-core 2.16 -> 2.22) every node greets us with
```
Welcome to {{ ansible_facts['hostname'] }} ({{ ansible_facts['distribution'] }} ...
```
The playbook didn't change. The deploy is green.

**Test**: /etc/motd on web1 and web2 shows the real host name, OS and environment; no template code left;
site.yml converges.
