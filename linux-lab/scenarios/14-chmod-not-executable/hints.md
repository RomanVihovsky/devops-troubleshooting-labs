## Hint 1
`ls -l /usr/bin/chmod`. `chmod` is just a wrapper around the `chmod()` **system call** - what
else on this box can make that syscall? (Interpreters, other tools, ...)
## Hint 2
Some ideas: `python3`/`perl` one-liners, `install -m`, `setfacl`, `cp` onto an executable
file, or running the binary through the dynamic loader.
## Hint 3
`sudo /lib64/ld-linux-x86-64.so.2 /usr/bin/chmod 755 /usr/bin/chmod`
or `sudo python3 -c 'import os; os.chmod("/usr/bin/chmod", 0o755)'`
