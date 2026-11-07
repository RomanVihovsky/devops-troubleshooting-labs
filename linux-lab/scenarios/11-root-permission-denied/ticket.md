# Root gets "Permission denied" running a script
**LNX-111** · P2 · Reporter: security team

`rotate-keys.service` fails every night with `Permission denied` (status=203/EXEC).
The script `/opt/tools/rotate-keys.sh` is `-rwxr-xr-x root root`, has a valid shebang,
and the service runs as root. Running it by hand as root: same error.

**Test**: `rotate-keys.service` succeeds and updates `/var/lib/rotate/last-run` - also after
the tools volume is re-mounted (as on a reboot).
