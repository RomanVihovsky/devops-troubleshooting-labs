## Hint 1
How did it die? `systemctl status data-indexer` (look at "Result" / "code="), and
`journalctl -u data-indexer` around a restart. Exit status 9 / SIGKILL means someone else killed it.
## Hint 2
(`dmesg` is not allowed inside this container - the journal has what you need.)
`systemctl show -p MemoryMax,MemoryCurrent,NRestarts data-indexer`, and watch
`MemoryCurrent` grow. `/sys/fs/cgroup/system.slice/data-indexer.service/memory.events`.
## Hint 3
The limit is fine - the app's cache is unbounded. Look at its configuration
(`systemctl cat data-indexer` -> EnvironmentFile). The vendor docs suggest ~50 items.
