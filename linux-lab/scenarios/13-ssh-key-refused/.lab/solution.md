# Solution - StrictModes rejects a group-writable home directory

**Root cause**: `/home/deploy` was handed to the shared `release` group and made `775`
(group-writable). With `StrictModes yes` (the default) sshd refuses public keys if the home
dir, `~/.ssh` or `authorized_keys` is writable by anyone but the owner/root - a release-team
member could otherwise swap the key. (Debian's sshd tolerates group-write only when the group
is the user's *private* group with no other members - here it isn't.)

**Diagnose**
```
# client
ssh -v deploy@10.77.0.10        # "Offering public key ... / Permission denied (publickey)"
# server
sudo journalctl -u ssh -n 20    # Authentication refused: bad ownership or modes for directory /home/deploy
namei -l /home/deploy/.ssh/authorized_keys
```

**Fix**: `sudo chmod g-w /home/deploy` (give the release team a separate drop directory instead).

**Interview notes**: other key-auth failures: wrong owner of `authorized_keys`, key type
disabled (`PubkeyAcceptedAlgorithms`, old `ssh-rsa` SHA-1), `AuthorizedKeysFile` pointing
elsewhere, account locked/expired (`chage -l`, `passwd -S`), `nologin` shell, `AllowUsers`,
SELinux context on `.ssh` (`restorecon -Rv ~/.ssh`), CRLF/whitespace in the key line.
