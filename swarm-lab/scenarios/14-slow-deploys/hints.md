## Hint 1
Reproduce on a node: `time docker stop <cid>` and `docker logs <cid>`. 30 s = the
`stop_grace_period`, after which Docker sends SIGKILL.
## Hint 2
Which process is **PID 1** in the container, and which process is the app?
`docker top <cid>` or `docker exec <cid> ps -o pid,ppid,args`.
## Hint 3
`docker stop` signals PID 1 only. A shell running a child (without `exec`) does not
forward signals - and PID 1 ignores signals it has no handler for. Check the
`entrypoint` in the stack and what that script does.
