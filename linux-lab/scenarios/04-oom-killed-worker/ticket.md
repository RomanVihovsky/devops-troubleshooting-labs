# The indexer keeps dying, silently
**LNX-104** · P2 · Reporter: search team

`data-indexer` dies every half a minute or so and systemd restarts it. Its own logs end
mid-sentence - no traceback, no error. Capacity planning gave it a hard memory budget
(`MemoryMax=96M`) and that budget **must stay**.

**Test**: `data-indexer` runs for 40 s without a single restart, `MemoryMax` is still 96M.
