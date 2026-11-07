# Solution - sudo ignores include files with a dot in the name

**Root cause**: `/etc/sudoers` ends with `@includedir /etc/sudoers.d`. sudo **skips files
whose names contain a `.` or end with `~`** in included directories (so editor backups and
`.rpmsave` files never become active). `deploy.conf` is silently ignored - and `visudo -c`
doesn't complain because it doesn't read it either.

**Diagnose**
```
sudo -l -U deploy                  # no rules for deploy
grep -n includedir /etc/sudoers
man sudoers | grep -A5 'includedir'
```

**Fix**
```
sudo mv /etc/sudoers.d/deploy.conf /etc/sudoers.d/deploy   # mode 0440, owner root
sudo visudo -c
sudo -l -U deploy
```

**Interview notes**: always edit with `visudo -f /etc/sudoers.d/<name>` (it locks and
syntax-checks; a syntax error can lock *everyone* out of sudo - recovery needs a root
shell, `pkexec visudo`, or single-user mode). Rules are matched last-match-wins, and
commands should be given with full paths.
