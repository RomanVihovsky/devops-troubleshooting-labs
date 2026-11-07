# Solution - systemd socket activation holds the port

**Root cause**: `legacy-status.socket` (enabled) makes **systemd (PID 1)** listen on :80 and
spawn `legacy-status@.service` per connection. Killing the per-connection process does
nothing - PID 1 still owns the listening socket, so nginx gets `EADDRINUSE`.

**Diagnose**
```
sudo ss -ltnp 'sport = :80'     # users:(("systemd",pid=1,fd=..))
systemctl list-sockets          # 0.0.0.0:80  legacy-status.socket
journalctl -u nginx -n 5
```

**Fix**
```
sudo systemctl disable --now legacy-status.socket   # (mask it to be sure)
sudo systemctl restart nginx
```

**Interview notes**: "address already in use" checklist: `ss -ltnp`, another instance of the
same service, socket units (cups, docker.socket, ssh.socket on newer Ubuntu), containers
publishing the port (`docker-proxy`), `TIME_WAIT` + missing `SO_REUSEADDR` on quick restarts,
and binding to a port < 1024 as non-root (that one is *permission denied*, not *in use*).
