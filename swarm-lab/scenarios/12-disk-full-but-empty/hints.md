## Hint 1
Find the container: `docker service ps app_web`, then on that node
`docker ps --filter label=com.docker.swarm.service.name=app_web`. Reproduce `df` vs `du`.
## Hint 2
`df` counts blocks the filesystem has allocated; `du` walks directory entries.
A file that was **deleted while a process still has it open** has no directory
entry but keeps its blocks. Look at `/proc/<pid>/fd` (`ls -l /proc/*/fd | grep deleted`)
or `lsof +L1` - inside the container or via the node (`lsof -p <host pid>`).
## Hint 3
Mitigate: truncate through the open descriptor: `: > /proc/<pid>/fd/<N>`.
Then ask why the file keeps growing and why it was deleted: check the service's
environment (`docker service inspect --pretty app_web`) - a debug setting left on?
