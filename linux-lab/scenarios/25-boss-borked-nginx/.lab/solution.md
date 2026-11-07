# Solution - three chained faults

1. **Config syntax**: `root /srv/shop` is missing its `;` - nginx parses the next line as more
   arguments to `root` -> `nginx -t` fails, nginx won't start.
2. **Permissions**: `assets/app.css` is `-rw------- root` - the `www-data` worker can't read it -> 403.
3. **File-descriptor limit**: a drop-in sets `LimitNOFILE=16` (with `worker_processes 1`).
   Every connection and every opened file needs an fd; under concurrency nginx logs
   `accept4() failed (24: Too many open files)` and requests stall/fail.

**Diagnose**
```
sudo nginx -t                                     # "invalid number of arguments in root"
curl -i localhost/assets/app.css; sudo tail /var/log/nginx/error.log   # 13: Permission denied
systemctl cat nginx                               # tuning.conf: LimitNOFILE=16
cat /proc/$(pgrep -o nginx)/limits | grep files
seq 50 | xargs -P50 -I{} curl -s -o /dev/null -w '%{http_code}\n' --max-time 2 localhost/ | sort | uniq -c
```

**Fix**: add the `;`, `chmod 644` the asset, remove the drop-in (or set e.g.
`LimitNOFILE=65535`), `systemctl daemon-reload && nginx -t && systemctl restart nginx`.
(Optionally `worker_processes auto;` and `worker_rlimit_nofile` in nginx.conf.)

**Interview notes**: in multi-fault incidents, fix one layer at a time and re-test after
each change. `nginx -t` before every reload; `worker_connections` must fit inside the fd limit.
