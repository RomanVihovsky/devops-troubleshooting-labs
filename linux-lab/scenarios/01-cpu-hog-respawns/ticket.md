# Killing the CPU hog doesn't help
**LNX-101** · P2 · Reporter: on-call

`srv` is sluggish. `top` shows one process burning a full CPU core. We killed it -
twice - and within a minute it was back. Nobody admits to running it.

**Test**: no process uses more than 50% CPU for 70 seconds, and `cron` keeps running
(other jobs depend on it).
