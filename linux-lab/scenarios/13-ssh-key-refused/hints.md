## Hint 1
The client only says "denied". The **server** says why: on srv, `sudo journalctl -u ssh -n 20`
(add `ssh -v` on the client for its side of the story).
## Hint 2
sshd's `StrictModes` refuses keys if the user's home, `~/.ssh` or `authorized_keys` can
be written by anyone other than the user (or root). `namei -l /home/deploy/.ssh/authorized_keys`.
## Hint 3
Group-writable counts too (`ls -ld /home/deploy`, `getent group release`). Home `755`/`750`, `~/.ssh` `700`, `authorized_keys` `600`, owned by deploy.
