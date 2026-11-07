# Solution - two typos in a unit file

**Root cause**: the edited unit has `User=inventry` (no such user -> `status=217/USER`) and
`ExecStart=/usr/bin/python3 /opt/inventory/bin/api.py` (file is `/opt/inventory/api.py` -
python exits with status 2). systemd reports the first one only; after fixing it you hit
the second.

**Diagnose**
```
systemctl status inventory-api        # code=exited, status=217/USER
journalctl -u inventory-api -n 20     # Failed to determine user credentials: No such process
systemctl cat inventory-api
id inventory; ls /opt/inventory
```

**Fix**
```
sudo systemctl edit --full inventory-api     # User=inventory, ExecStart=... /opt/inventory/api.py
sudo systemctl daemon-reload
sudo systemctl reset-failed inventory-api && sudo systemctl restart inventory-api
```

**Interview notes**: the 2xx codes are systemd's own (`203/EXEC` binary not
found/executable, `217/USER`, `226/NAMESPACE`, `200/CHDIR`...). Forgetting `daemon-reload`
means systemd keeps running the *old* unit (it warns: "unit file changed on disk").
`systemd-analyze verify <unit>` lints units; `StartLimitBurst` explains "start request
repeated too quickly" (`reset-failed`).
