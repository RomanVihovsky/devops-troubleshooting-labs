## Hint 1
Find it (`top`, press `c` for full command lines; `ps -eo pid,ppid,pcpu,cmd --sort=-pcpu | head`).
Does it look like a kernel thread? Kernel threads have PPID 2 and no `/proc/<pid>/exe`.
## Hint 2
Something restarts it. Who is its parent / which cgroup is it in?
`systemctl status <pid>`, `cat /proc/<pid>/cgroup`, `ps -o ppid= -p <pid>`. What runs things every minute?
## Hint 3
Look at **root's** crontab (`sudo crontab -l`), not only `/etc/cron.d`. Remove the entry, then kill the process.
