# Solution - teach the dynamic loader a new library directory

**Root cause**: `libjq.so.1` was moved to `/opt/vendor/lib`, which is not in the dynamic
loader's search path, and `ldconfig` was re-run, so the cache no longer knows it.

**Diagnose**
```
ldd /usr/bin/jq                 # libjq.so.1 => not found
ldconfig -p | grep libjq        # nothing
ls -l /opt/vendor/lib
```

**Fix** (system-wide, works for services too):
```
echo /opt/vendor/lib | sudo tee /etc/ld.so.conf.d/vendor.conf
sudo ldconfig
ldd /usr/bin/jq                 # => /opt/vendor/lib/libjq.so.1
```
`LD_LIBRARY_PATH` in `/etc/profile` would only fix login shells - not systemd units, cron,
or setuid programs (which ignore it).

**Interview notes**: search order = DT_RPATH, `LD_LIBRARY_PATH`, DT_RUNPATH, `ld.so.cache`,
default dirs. `ldconfig` also creates the SONAME symlinks (`libjq.so.1 -> libjq.so.1.0.4`).
Related: "version `GLIBC_2.34' not found" = built on a newer distro; `patchelf --set-rpath`
for vendored apps; `LD_DEBUG=libs <cmd>` traces the search.
