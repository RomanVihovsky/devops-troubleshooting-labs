# Hundreds of <defunct> processes
**LNX-103** · P3 · Reporter: monitoring

The process-count alert on `srv` fired: `ps` shows hundreds of processes marked
`<defunct>` (state `Z`). `kill -9` on them does nothing. Someone restarted the box last
week; they came back within minutes.

**Test**: zero zombie processes for 15 s, and `report-worker` keeps running.
