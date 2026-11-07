# Solution - immutable and append-only file attributes

**Root cause**: `/etc/app/app.conf` has the **immutable** attribute (`chattr +i`): nobody,
not even root, can modify, delete, rename or chmod it until the flag is removed. The audit
log has **append-only** (`chattr +a`): it can only grow.

**Diagnose**
```
lsattr /etc/app/app.conf /var/log/app/audit.log
# ----i---------e------- /etc/app/app.conf
# -----a--------e------- /var/log/app/audit.log
```

**Fix**
```
sudo chattr -i /etc/app/app.conf
sudo sed -i 's/^mode = .*/mode = production/' /etc/app/app.conf
```
Leave `+a` on the audit log (needs `CAP_LINUX_IMMUTABLE` to change - that's the point).

**Interview notes**: "root gets Operation not permitted" checklist: file attributes
(`lsattr`), read-only mount (`findmnt`), SELinux/AppArmor (`ls -Z`, `ausearch`), ACLs
(`getfacl`), the file being on an overlay lower layer / NFS with root_squash, or a
container without the capability. Attackers also use `chattr +i` to protect implants.
