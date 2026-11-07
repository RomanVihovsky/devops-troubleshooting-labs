# Create the lab VM (a sibling VM in VirtualBox)

The Kubernetes cluster runs in its **own VirtualBox VM**, next to your desktop VM - not nested
inside it. Your desktop VM keeps the `./lab` CLI and talks to the lab VM over SSH. If the lab VM
ever crashes, your desktop VM keeps running.

```
physical machine (VirtualBox 7.0)
├── desktop VM  "desktop"         (this one: Ubuntu 22.04, Claude, ./lab CLI)   192.168.56.10 (DHCP)
│        │ ssh lab@192.168.56.20 / kubectl -> https://192.168.56.20:6443
│        ▼
└── lab VM      "k8slab"          (new: Ubuntu Server, Docker + kind cluster)  192.168.56.20 (static)
         both VMs: Adapter 1 = NAT (internet), Adapter 2 = Host-only "vboxnet0" (VM <-> VM)
```

## 1. Download

**Ubuntu Server 24.04 LTS** (latest point release), "live server" ISO, amd64:
<https://ubuntu.com/download/server> -> file `ubuntu-24.04.x-live-server-amd64.iso` (~2.7 GB).
Verify it against the `SHA256SUMS` file published next to it on <https://releases.ubuntu.com/24.04/>.

(Ubuntu Server 26.04 LTS works too; 24.04 is the most tested with Docker and kind.)

## 2. Resources

| Profile | vCPU | RAM | Disk (dynamic VDI) | Cluster |
|---|---|---|---|---|
| **Recommended** | **6** | **12 GB** | **60 GB** | 1 control plane + 3 workers, all addons |
| Minimum | 4 | 8 GB | 40 GB | 1 control plane + 2 workers |

Budget check on the physical machine: desktop VM (now 8 vCPU / ~20 GB RAM) + lab VM + ~4 GB for
the physical OS must fit in physical RAM. Examples:
* 64 GB physical -> keep everything as is, use the Recommended profile.
* 32 GB physical -> lower the desktop VM to ~12 GB while you practise, lab VM 12 GB.
* 16 GB physical -> Minimum profile, desktop VM ~6 GB (tight; expect swapping on the host).

vCPUs: the Ryzen 7 5800H has 16 threads; desktop 8 + lab 6 = 14 is fine.

## 3. VirtualBox settings for the new VM

Create: *Machine -> New*, name `k8slab`, ISO = the Ubuntu Server ISO, type Linux / Ubuntu (64-bit).
Tick **"Skip Unattended Installation"** (so you choose the options below yourself).

| Setting | Value | Why |
|---|---|---|
| System > Motherboard | RAM per profile, Boot order: Hard Disk, Optical; EFI optional | |
| System > Processor | vCPUs per profile; **Enable Nested VT-x/AMD-V: OFF**; PAE/NX: on | nested AMD-V is what crashed VirtualBox; kind doesn't need it |
| System > Acceleration | Paravirtualization: **Default** (KVM); Hardware virtualization on | normal for Linux guests |
| Display | Graphics: VMSVGA, 16 MB, **3D acceleration OFF** | headless server; fewer moving parts |
| Storage | SATA/AHCI controller, VDI **dynamically allocated**, size per profile, tick *Solid-state Drive* | thin, grows as needed |
| Audio / USB | disabled | not needed |
| Network > Adapter 1 | **NAT** | internet (apt, images) |
| Network > Adapter 2 | **Host-only Adapter**, name `vboxnet0` (Windows: "VirtualBox Host-Only Ethernet Adapter") | VM <-> VM traffic |

If no host-only network exists yet: *File -> Tools -> Network Manager -> Host-only Networks -> Create*.
Defaults are fine (192.168.56.1/24, DHCP server on). The lab VM gets a **static** address
(192.168.56.20) outside the DHCP range (VirtualBox hands out from .101 upwards).

### Your desktop VM (this one) also needs the host-only network - one time

1. Shut this VM down (save your work).
2. Settings -> Network -> **Adapter 2**: Enable, *Host-only Adapter*, same `vboxnet0`.
3. While you're there - **System -> Processor -> Enable Nested VT-x/AMD-V: OFF**
   (nothing here needs it, and it's the feature that crashed). If VirtualBox ever halts again,
   also try Display -> 3D acceleration OFF.
4. Boot. Ubuntu Desktop picks up the second NIC via DHCP (192.168.56.10x).

## 4. Install Ubuntu Server in the lab VM

Installer choices:
* Language/keyboard: yours. Type: **Ubuntu Server (minimized)** is fine.
* Network: `enp0s3` (NAT) DHCP - leave it. `enp0s8` (host-only): *Edit IPv4 -> Manual*:
  subnet `192.168.56.0/24`, address `192.168.56.20`, gateway **empty**, name servers empty.
* Storage: use entire disk, **untick "Set up this disk as an LVM group"** (simpler; all space on `/`).
* Profile: your name, server name `k8slab`, username **`lab`**, a password you'll remember.
* SSH: **Install OpenSSH server: yes**. Leave "Import SSH key" empty.
* Featured snaps: **none** (don't pick docker/microk8s - the lab installs what it needs).
* Reboot, remove the ISO when asked.

Then on the lab VM console, log in as `lab` and add the desktop VM's key:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF4pyGk6UWHZMtA07+6GFz30s2RZqeb6ipd0F6M0ADQs k8slab-from-desktop' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo 'lab ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/lab && sudo chmod 440 /etc/sudoers.d/lab
ip -br a     # enp0s8 must show 192.168.56.20/24
```

(The private key is `kubernetes-lab/.state/labvm_key` on the desktop VM. The sudoers line lets the
lab provision the VM without asking for the password every time; remove it later if you like.)

## 5. Tell me it's ready

From the desktop VM this must work:
```bash
ssh -i ~/devops/practical/kubernetes-lab/.state/labvm_key lab@192.168.56.20 hostname
```
Then I continue with the cautious spike (section 6 of PLAN.md): provision Docker + kind over SSH,
1-node cluster with the health tripwire, then 4 nodes, 30-minute soak, then the golden snapshot
(VirtualBox snapshot of the lab VM = instant full reset).

## Optional: VirtualBox log after a crash

*VirtualBox Manager -> right-click the VM -> Show Log... -> VBox.log* (or VBox.log.1 for the run
before). Search for `Guru Meditation`, `!!!!`, `VERR_` or `TRIPLE_FAULT` and paste ~30 lines around
it - that names the exact cause of a halt.
