# Solution - restore the execute bit without chmod

**Root cause**: `/usr/bin/chmod` is `-rw-r--r--`; the kernel won't exec it, so you can't
use it to fix itself.

**Ways out** (all just call the `chmod()` syscall some other way):
```
sudo /lib64/ld-linux-x86-64.so.2 /usr/bin/chmod 755 /usr/bin/chmod   # loader maps & runs it
sudo python3 -c 'import os; os.chmod("/usr/bin/chmod", 0o755)'
sudo perl -e 'chmod 0755, "/usr/bin/chmod"'
sudo setfacl -m u::rwx,g::rx,o::rx /usr/bin/chmod
sudo install -m 755 /usr/bin/chmod /tmp/chmod && sudo /tmp/chmod 755 /usr/bin/chmod
```
then `sudo chmod 755 /usr/local/bin/deploy.sh`.

**Interview notes**: a favourite "how well do you know Linux" question. It shows the
difference between a *program* and the *syscall* it wraps, how the dynamic loader can run
a binary directly, and that `noexec`/mode bits don't stop interpreters (see scenario 11).
