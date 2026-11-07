## Hint 1
What is `/srv/uploads` right now? `findmnt /srv/uploads`. And where did the app write
*before* that was mounted?
## Hint 2
A mount hides whatever was in the directory underneath it - the files are still on the
root filesystem, just not reachable through that path. How can you look *under* a mount
point without unmounting it (and losing nothing)?
## Hint 3
Bind-mount the root filesystem elsewhere: `sudo mkdir /mnt/rootfs && sudo mount --bind / /mnt/rootfs`,
then look in `/mnt/rootfs/srv/uploads/`. Copy the invoices onto the mounted volume.
(Unmounting the tmpfs volume would destroy the 3 existing files.)
