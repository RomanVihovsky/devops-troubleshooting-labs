# k8s-w2 doesn't come back after the patch reboot
**INC-2334** · P2 · Reporter: platform team

k8s-w2 was rebooted after patching. It is up (SSH works) but stays **NotReady**. Before the reboot,
someone added "a bit of swap so builds don't OOM". The node must also survive the **next** reboot.

**Test**: k8s-w2 is Ready with its kubelet active; no swap is active; nothing in `/etc/fstab` turns swap on
at the next boot.
