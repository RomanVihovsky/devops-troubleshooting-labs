# Load is high, but the CPU is idle
**LNX-102** · P2 · Reporter: media team

Since the "right-sizing" change yesterday, `thumbnailer` takes minutes per image.
`uptime` shows the load average climbing, yet `top` says the CPUs are mostly idle.
No errors in its logs, no OOM kills, `free -m` shows plenty of memory.

**Test**: no processes stuck in uninterruptible sleep (D state) for 15 s, while
`thumbnailer` keeps running with all 4 workers.

(Note: load average is a *host-wide* number inside containers, so your laptop's own
load shows up in it too - judge by the processes on `srv`.)
