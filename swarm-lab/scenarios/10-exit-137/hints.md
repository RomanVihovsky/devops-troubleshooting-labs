## Hint 1
137 = 128 + 9 = SIGKILL. No healthcheck here, so who sends SIGKILL to a process?
## Hint 2
On a node that ran a task: `docker ps -a --filter label=com.docker.swarm.service.name=app_web`,
then `docker inspect -f '{{.State.OOMKilled}} {{.HostConfig.Memory}}' <cid>`.
The kernel also logs it: `dmesg -T | grep -i -A3 oom` (on the node).
## Hint 3
The cgroup memory limit is smaller than what the process needs (cache + Python itself).
Look at `deploy.resources.limits.memory` and size it with headroom.
