# error while loading shared libraries
**LNX-120** · P2 · Reporter: data team

The nightly report (`report.service`) and everyone's `jq` fail with:
`jq: error while loading shared libraries: libjq.so.1: cannot open shared object file`.
Last night's "cleanup" moved the vendor libraries to `/opt/vendor/lib`, which is now the
**official location** - don't move or copy them back into `/usr/lib`.

**Test**: `jq --version` works for every user and inside systemd services (no shell
profile), with the library still living in `/opt/vendor/lib`.
