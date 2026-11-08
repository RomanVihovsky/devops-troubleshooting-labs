kubernetes-lab - VirtualBox kit
================================

This folder creates the lab's node VMs next to your desktop VM. It only uses VBoxManage and only
touches the VMs listed in nodes.csv (k8s-gw, k8s-cp1, k8s-w1..3, spare k8s-w4).
Everything inside the VMs (packages, Kubernetes, scenarios) is done by ./lab from the desktop VM over SSH.

Windows:        k8slab.bat <command>      (cmd or PowerShell, in this folder; no admin rights needed)
Linux / macOS:  ./k8slab.sh <command>

  check                     VirtualBox version, host-only network 192.168.56.1, free disk
  create [nodes]            download + verify the Ubuntu 24.04 image once, create and boot the VMs
  start | stop [nodes]      start headless / ACPI shutdown (power off after 90 s)
  status                    state, IP and current snapshot of every node
  snapshot NAME [nodes]     stop, snapshot (replaces one of the same name), start
  restore NAME [nodes]      power off, restore the snapshot, start
  destroy [nodes]           power off and delete the VMs and their disks (asks first)

Nodes are named as in nodes.csv (k8s-cp1) or short (cp1). Default: all except role "spare".

Where to run it
---------------
This folder is a complete kit: kubernetes-lab/infra/vbox in a git checkout (e.g. the dev branch fetched
on Windows), or the copy that "./lab vm kit" puts into .state/kit / the VirtualBox shared folder.
seed.iso carries the SSH public key of the desktop VM that built it (.state/labvm_key.pub). If you
cloned someone else's repo, run "./lab vm kit" on your own desktop VM first and use that seed.iso.

First time
----------
1. k8slab.bat check      -> fix anything it reports (host-only network, disk space)
2. k8slab.bat create     -> ~600 MB download once, then 5 VMs boot headless (1-2 min)
3. On the desktop VM:    ./lab vm wait

What create does
----------------
- Downloads the pinned Ubuntu 24.04 cloud VMDK (URL + SHA256 in kit.env) to %USERPROFILE%\k8slab\cache
  and converts it once to base\k8slab-base-<release>.vdi (40 GB, multiattach: every VM writes to its
  own differencing disk, the base stays untouched).
- Per VM: Ubuntu_64, CPUs/RAM from nodes.csv, nested VT-x/AMD-V off, NIC1 NAT (internet),
  NIC2 host-only with a fixed MAC (the VM finds its name and IP by that MAC), serial console
  logged to logs\<vm>-console.log, seed.iso as DVD (cloud-init: user "lab" + the desktop's SSH key).
- VMs live in VirtualBox's default machine folder, group /k8slab. Set K8SLAB_HOME=D:\k8slab before
  running the script to keep the image, base disk and logs elsewhere.

Snapshots
---------
./lab resets the cluster from inside the VMs. A VirtualBox snapshot is the panic button:
  k8slab.bat snapshot baseline      (after ./lab tells you the cluster baseline is ready)
  k8slab.bat restore baseline       (if a VM is broken beyond SSH)

If something goes wrong
-----------------------
- A VM boots but ./lab vm wait never sees it: look at logs\<vm>-console.log (cloud-init output).
- Green turtle icon in a VM's status bar: VirtualBox runs on top of the Windows hypervisor (Hyper-V,
  WSL2, Memory integrity). It works, but slower. check warns about it.
- VirtualBox halts or "Guru Meditation": VM window > Machine > Show Log (VBox.log), search for
  "Guru Meditation", "!!!!" or "VERR_" and send ~30 lines around it.
