## Hint 1
`ldd $(command -v jq)` shows which libraries the dynamic loader can't find.
`ls -l /opt/vendor/lib`.
## Hint 2
How does the loader search? `RPATH/RUNPATH` in the binary, `LD_LIBRARY_PATH`, then the
cache built from `/etc/ld.so.conf` + `/etc/ld.so.conf.d/*.conf` (`ldconfig -p | grep jq`).
Which of these also works for systemd services and every user?
## Hint 3
`echo /opt/vendor/lib | sudo tee /etc/ld.so.conf.d/vendor.conf && sudo ldconfig`.
