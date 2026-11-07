# Solution - missing execute (search) bit on a parent directory

**Root cause**: `/srv/www` is `drwxr-x--- root root`. nginx workers run as `www-data`,
which is "other" there and has no `x` on the directory, so it cannot traverse into
`/srv/www/shop` - even though the file itself is world-readable.

**Diagnose**
```
sudo tail -2 /var/log/nginx/error.log     # open() ".../index.html" failed (13: Permission denied)
namei -l /srv/www/shop/index.html         # drwxr-x--- root root www  <- no x for others
sudo -u www-data cat /srv/www/shop/index.html
```

**Fix**: `sudo chmod o+x /srv/www` (or `chmod 755`, or `chgrp www-data` + `g+x`).
Never `chmod -R 777`.

**Interview notes**: for directories `r` = list names, `x` = traverse/access entries,
`w` = create/delete entries (with `x`). Other 403 causes: missing `index` file with
autoindex off, SELinux label (`httpd_sys_content_t`, check `ls -Z`, `ausearch -m avc`),
`deny` rules, symlinks with `disable_symlinks`.
