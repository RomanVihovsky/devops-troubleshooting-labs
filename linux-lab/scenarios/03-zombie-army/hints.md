## Hint 1
A zombie has already exited - there is nothing left to kill. It only stays in the
process table until its **parent** collects its exit status with `wait()`.
`ps -eo pid,ppid,state,cmd | awk '$3=="Z"'` - who is the parent?
## Hint 2
Killing/restarting the parent makes the zombies disappear (they are re-parented to PID 1,
which reaps them)... but the parent will produce new ones. Why does it not reap its children?
Look at how it is started and configured (`systemctl cat report-worker`, its config file).
## Hint 3
`/etc/report-worker.conf`. Fix the setting, restart the service, confirm with `ps`.
