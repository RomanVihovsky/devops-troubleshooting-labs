# Host setup - the lab VMs in VirtualBox

The cluster runs in **five sibling VirtualBox VMs** next to your desktop VM, not nested inside it.
Nested virtualization crashed VirtualBox here in Phase 0, so nothing is virtualized inside the desktop VM.
The VMs are created by a small kit you run once on the VirtualBox host (`k8slab.bat` on Windows,
`k8slab.sh` on Linux/macOS). After that, `./lab` on the desktop VM does everything over SSH. It never
talks to Windows or to VirtualBox.

```
physical machine: Windows 11 + VirtualBox 7.x       host-only network 192.168.56.0/24 (host = .1)
├─ desktop VM (Ubuntu, ./lab)    NIC1 NAT · NIC2 host-only, DHCP .101+
├─ k8s-gw   192.168.56.20        1 vCPU 3 GB   API load balancer, registry, Gitea, OpenBao, NFS, DNS, NTP
├─ k8s-cp1  192.168.56.21        2 vCPU 4 GB   control plane (kubeadm, stacked etcd)
├─ k8s-w1   192.168.56.31        2 vCPU 4 GB   worker, zone-a
├─ k8s-w2   192.168.56.32        2 vCPU 4 GB   worker, zone-a
├─ k8s-w3   192.168.56.33        2 vCPU 4 GB   worker, zone-b
└─ k8s-w4   192.168.56.34        2 vCPU 2 GB   spare - only for "join a node" scenarios (create w4)
every node VM: NIC1 NAT (internet, default route) · NIC2 host-only with a fixed MAC (identity + static IP)
```

The source of truth is [infra/vbox/nodes.csv](../infra/vbox/nodes.csv). The kit, the seed ISO and `./lab`
all read it.

## 1. One-time: the desktop VM joins the host-only network

`./lab` reaches the nodes over the host-only network, so this VM needs a second NIC:

1. Save your work and shut this desktop VM down.
2. VirtualBox Manager → this VM → *Settings* → *Network* → **Adapter 2**: enable it, *Attached to:
   Host-only Adapter*, name: the adapter whose IP is 192.168.56.1 (usually
   "VirtualBox Host-Only Ethernet Adapter").
   If none exists: *File → Tools → Network Manager → Host-only Networks → Create*, then
   192.168.56.1 / 255.255.255.0 with the DHCP server on.
3. While you're there:
   - *System → Processor → Enable Nested VT-x/AMD-V*: **off**;
   - optionally lower this VM to **6 vCPU** (see the budget below).
4. Boot. Ubuntu picks up the second NIC via DHCP (192.168.56.10x). Check it with `./lab vm check`.

Optional, so `./lab vm kit` can drop the kit straight into the VirtualBox shared folder
(`/home/shared`):

```bash
sudo usermod -aG vboxsf "$USER"     # then log out and back in
```

## 2. Build the kit (desktop VM)

```bash
./lab vm kit
```

This refreshes the kit in two places:
- `infra/vbox/`, which is committed. Commit + push, then fetch the branch on Windows and run the kit from
  your clone (`kubernetes-lab\infra\vbox\k8slab.bat`).
- `.state/kit/`, a CRLF copy. It is also copied into the shared folder (`/home/shared/k8slab-kit`) when
  that is writable.

The kit contains:

| File | Purpose |
|---|---|
| `k8slab.bat` / `k8slab.sh` | Create and manage the VMs (same commands) |
| `nodes.csv` | The node table |
| `kit.env` | Pinned Ubuntu image URL + SHA256, disk size, group |
| `seed.iso` | cloud-init: user `lab` with this VM's SSH key, MAC → hostname/IP |
| `README.txt` | The kit's README |

Optional sanity check before touching VirtualBox, ~5-10 min:

```bash
./lab vm seedtest
```

It boots the same Ubuntu build with the seed under QEMU software emulation (no `/dev/kvm`, no nested
virtualization) and checks user, key, hostname and IP.

## 3. Create the VMs (Windows)

In your clone (`kubernetes-lab\infra\vbox`) or the copied kit folder, open a terminal:

```bat
git fetch origin && git checkout dev && git pull
cd kubernetes-lab\infra\vbox
.\k8slab.bat check
.\k8slab.bat create
```

In `cmd` the `.\` prefix isn't needed. `seed.iso` holds the public key of the desktop VM that ran
`./lab vm kit`; after cloning someone else's repo, rebuild it on your own desktop VM.

- `check`:
  - VirtualBox ≥ 7.0;
  - the host-only adapter that owns 192.168.56.1;
  - ≥ 35 GB free under `%USERPROFILE%\k8slab`;
  - a warning if the Windows hypervisor is active.
- `create`:
  - downloads the Ubuntu 24.04 VMDK once (~600 MB) and verifies its SHA256;
  - converts it to one multiattach base disk;
  - creates the 5 VMs (group `/k8slab`) and boots them headless.

No admin rights are needed. To create only some of them: `k8slab.bat create gw cp1`.

## 4. Check from the desktop VM

```bash
./lab vm wait      # SSH, hostname, static IP, cloud-init done - for every node
./lab vm status    # uptime, memory, disk
./lab node cp1     # a shell on the control-plane node
```

## Budget

| Resource | Budget |
|---|---|
| Physical RAM | 19 GB for the 5 VMs (+2 GB with w4), on top of the desktop VM and Windows |
| vCPU | 9 for the VMs. Desktop 8 + 9 = 17 on a 16-thread CPU is mild overcommit; lower the desktop VM to 6 vCPU if things stall |
| Windows disk | ~25 GB under `%USERPROFILE%\k8slab` and the VirtualBox machine folder |

## Day to day (on the VirtualBox host)

| Command | Effect |
|---|---|
| `k8slab.bat stop` / `start` | ACPI shutdown, then start headless |
| `k8slab.bat status` | State and current snapshot per VM |
| `k8slab.bat snapshot baseline` | The panic button, taken once when `./lab` says the baseline is ready |
| `k8slab.bat restore baseline` | Only if a VM is broken beyond SSH |
| `k8slab.bat destroy` | Delete the VMs (asks first) |

## Troubleshooting

- **A VM never shows up in `./lab vm wait`**: read `%USERPROFILE%\k8slab\logs\<vm>-console.log`, the serial
  console with the cloud-init output. "no NIC of this VM matches" means the NIC2 MAC differs from
  `nodes.csv`.
- **Green turtle in the VM status bar**: VirtualBox is running on the Windows hypervisor (NEM) because
  Hyper-V, WSL2, VBS or Memory integrity is on. It works, but slower. Whether to turn those off is your call.
- **VirtualBox halts / Guru Meditation**: *Machine → Show Log* (VBox.log). Search for `Guru Meditation`,
  `!!!!` or `VERR_` and paste ~30 lines around it.
