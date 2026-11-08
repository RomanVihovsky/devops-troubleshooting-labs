## Hint 1
Read the full error (`-vvv`): which commands did Ansible try to give `acme` access to its temp files?
(`setfacl`, `chown`, `chmod +a` ...). What did the old image have that the minimal one lacks?

## Hint 2
Becoming an **unprivileged** user means the files Ansible uploaded as `ansible` must become readable for `acme`.
The safe way is a POSIX ACL - which needs the `setfacl` command. Pipelining avoids temp files for modules, but
`template`/`copy` still transfer a file.

## Hint 3
Install the `acl` package (it is in the mirror) in a task that runs as root **before** the `become_user: acme` task.
