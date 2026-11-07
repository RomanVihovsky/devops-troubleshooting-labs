# Solution - files hidden under a mount point

**Root cause**: after a reboot the uploads volume was not mounted, so the app wrote the 6
invoices into the plain directory `/srv/uploads` on the **root filesystem**. When the volume
was mounted on top, it *covered* those files: they still exist on `/`, but the path now
shows the volume's contents. `du` of `/` still counts them - a classic "where did my disk
space go?" too.

**Diagnose**
```
findmnt /srv/uploads                     # tmpfs mounted here
sudo mkdir /mnt/rootfs && sudo mount --bind / /mnt/rootfs
ls -l /mnt/rootfs/srv/uploads            # the 6 invoices
```
(`mount --bind` of `/` does not carry submounts, so you see what's underneath.)

**Fix**
```
sudo cp -a /mnt/rootfs/srv/uploads/invoice-* /srv/uploads/
sudo umount /mnt/rootfs
```
Don't `umount /srv/uploads` - a tmpfs loses its contents (the 3 existing files) when unmounted.
Prevent recurrence: make the app's unit depend on the mount
(`RequiresMountsFor=/srv/uploads`), or `chattr +i` the empty mount-point directory.
