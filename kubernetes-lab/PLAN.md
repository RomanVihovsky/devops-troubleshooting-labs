# kubernetes-lab - plan (v2, approved 2026-11-08)

A local break/fix playground for **Kubernetes troubleshooting**:
- the CKA "Troubleshooting" domain (30% of the exam);
- the scenario questions interviewers ask;
- failure classes from real postmortems (k8s.af);
- since v2, **Helm + Argo CD GitOps and secret management** (from
  [kubernetes_lab_research_english.md](kubernetes_lab_research_english.md)).

Same workflow as `../ansible-lab` and `../terra-labs`:

```
./lab start D03        # broken on purpose, ticket printed
./lab node cp1         # "ssh into the node" of a CKA task; kubectl/helm/argocd work on the desktop
./lab verify           # PASS / FAIL against the ticket's "Test"
./lab hint | solution | solve
./lab interview        # 3 random tickets against the clock
```

Companion documents:
- [docs/HOST-SETUP.md](docs/HOST-SETUP.md) - the VirtualBox VMs: one-time steps and the kit;
- [docs/CATALOG.md](docs/CATALOG.md) - every scenario: symptom, emulation, verification (spoilers!);
- [docs/INTERVIEW-QUESTIONS.md](docs/INTERVIEW-QUESTIONS.md) - interview questions with the key points of a good answer.

---

## 0. Decisions

| Date | Question | Answer |
|---|---|---|
| 2026-11-04 | Build scope | Waves, each self-tested |
| 2026-11-04 | Downloads | Approved: a few GB once, offline afterwards |
| 2026-11-04 | Nested KVM in the desktop VM | **Crashed VirtualBox** (§9). Nothing is virtualized inside the desktop VM, ever |
| 2026-11-08 | Cluster | **Real kubeadm cluster in sibling VirtualBox VMs**. kind dropped |
| 2026-11-08 | Topology | 1 control plane + 3 workers + a gateway VM (~32 GB free for it); spare w4 for join scenarios |
| 2026-11-08 | Who creates the VMs | **A kit you run on the VirtualBox host** (`k8slab.bat` / `k8slab.sh`). No SSH into Windows: `./lab` only talks to the VMs |
| 2026-11-08 | GitOps / secrets track | In full: Helm charts, Gitea, Argo CD, Sealed Secrets, ESO + OpenBao, SOPS + age |

## 1. What we're preparing for

| Source | What it tells us |
|---|---|
| CKA curriculum (Feb 2025 revision) | Troubleshooting is **30%**, the biggest domain: clusters and nodes, cluster components, monitoring, container output, services and networking. Helm, Kustomize, Gateway API and CRDs/operators were added |
| Killer Shell / Killercoda CKA drills | Broken static-pod manifests (several errors at once), broken controller-manager, broken kubelet config, kubeadm upgrades, etcd backup/restore |
| Interview guides | Pod states, node NotReady and **what happens to StatefulSet pods**, probes, `logs --previous`, Pending with free capacity |
| k8s.af failure stories | DNS (`ndots:5`, CoreDNS OOM), conntrack races, CPU throttling, etcd quota, webhooks taking clusters down |
| Research report (2026-11-08) | Multi-VM VirtualBox for realism. Helm + Argo CD (render vs Helm-managed release, drift, AppProjects). Sealed Secrets → ESO + Vault/OpenBao → SOPS. RBAC, NetworkPolicy, TLS, encryption at rest, rotation, audit. 8 proposed scenarios |

## 2. Environment

### 2.1 Shape

```
Windows 11 + VirtualBox 7.2          you run once:  k8slab.bat create   (Linux/macOS: ./k8slab.sh create)
│  host-only 192.168.56.0/24 (host .1)
├─ desktop VM (Ubuntu)   ./lab, kubectl, helm, argocd, kubeseal, sops+age, bao, stern
│     ssh lab@192.168.56.x => provisioning, scenarios, resets;  kubectl => https://192.168.56.20:6443
├─ k8s-gw   .20  haproxy :6443 (k8s-api.lab -> cp1), registry :5000 + read-only htpasswd copy :5001,
│               nginx :8080 (pinned files + flat apt repo), Gitea :3000, OpenBao :8200 (TLS, lab CA), NFS,
│               chrony. Docker-free; *.lab names: /etc/hosts on the VMs + a CoreDNS "lab" zone for pods
├─ k8s-cp1  .21  kubeadm control plane, stacked etcd
├─ k8s-w1 .31 zone-a · k8s-w2 .32 zone-a · k8s-w3 .33 zone-b
└─ reserved .22/.23 (HA later) · .34 k8s-w4 (spare) · .200-.220 MetalLB pool
```

| VM | vCPU | RAM | NIC1 | NIC2 |
|---|---|---|---|---|
| k8s-gw | 1 | 3 GB | NAT, DHCP, default route | host-only, fixed MAC, static IP |
| k8s-cp1 | 2 | 4 GB | same | same |
| k8s-w1..w3 | 2 | 4 GB | same | same |
| total | 9 | 19 GB | | |

Why this shape:
- **Isolation**: privileged things run in their own VMs, never in the desktop VM.
- **Realism**: real kernels, systemd, kubelet, containerd, swap, modules, clocks and NICs.
- **Fault classes kind can't do**: node partitions, reboots, swap, `br_netfilter`, clock skew and kubeadm upgrades
  become real.

Network decisions:
- **Host-only, not an Internal Network**: the desktop and Windows must reach the nodes and MetalLB IPs, and an
  Internal Network would need a router VM.
- **Pinned addresses**: every VM's NAT NIC is 10.0.2.15 (the classic kubeadm-on-VirtualBox trap). kubelet
  `--node-ip`, kubeadm `advertiseAddress` and Calico autodetection are pinned to 192.168.56.0/24. Calico uses
  `cidr=`, not an interface name: the seedtest showed the names differ (QEMU `ens8`, VirtualBox `enp0s8`).
- **Overlay**: pod CIDR 10.244.0.0/16, Calico VXLAN. Services 10.96.0.0/12.
- **API endpoint**: `controlPlaneEndpoint: k8s-api.lab:6443` goes through haproxy on gw. certSANs include .20, so
  the desktop kubeconfig needs no `/etc/hosts`.
- **Offline gate**: an nft drop of NAT egress on every VM. Nothing may need the internet after the build.

### 2.2 The VirtualBox kit (`infra/vbox/`, built by `./lab vm kit`)

| Piece | Role |
|---|---|
| `nodes.csv` | Single source of truth: name, cpus, mem, ip, NAT MAC, host-only MAC, role. Read by both scripts, `./lab` and the seed |
| `k8slab.bat` / `k8slab.sh` | Same commands: `check`, `create`, `start`, `stop`, `status`, `snapshot`, `restore`, `destroy`. Only VBoxManage, only `k8s-*` VMs from `nodes.csv`, no admin rights |
| Ubuntu image | Release VMDK + SHA256 from `versions.env`, downloaded once, converted to one base VDI; each VM gets its own full copy (`clonemedium`, ~2-3 GB each at first) |
| `seed.iso` | One generic cloud-init NoCloud seed for all VMs, built by `tools/mkseed.py` (pycdlib wheel, no pip/sudo). It holds user `lab` + the desktop's key, and network-config that matches both NICs of every node by MAC. `k8slab-identity` sets the hostname and `/etc/hosts` from the NIC2 MAC |
| Delivery | `./lab vm kit` copies the kit into the VirtualBox shared folder when writable, otherwise leaves it in `.state/kit/` |

### 2.3 Provisioning and baseline (`./lab`, over SSH)

1. `./lab vm wait`: SSH, identity and cloud-init done on every VM.
2. `./lab vm provision`: gw first, then the nodes in parallel through gw's file server, flat apt repo and
   registry mirror, so the Kubernetes downloads happen once (Ubuntu's own packages still come from the Ubuntu
   mirror).
   - gw (no container runtime): nginx file server + flat apt repo, the registry (distribution, every pinned image
     copied once with crane; a read-only htpasswd copy on :5001), haproxy, chrony, NFS, Gitea, OpenBao.
   - nodes: containerd 2.x, kubeadm/kubelet/kubectl 1.36 and 1.37, crictl, etcdctl, images pre-pulled.
3. `./lab cluster build --version 1.36`: kubeadm v1beta4 init + joins, Calico, CoreDNS, metrics-server,
   MetalLB L2, Traefik (Ingress + Gateway API), local-path, csi-driver-nfs.
   - Then it upgrades to 1.37 with the upgrade scenario's reference fix, so the baseline proves the path.
   - Then it adds the GitOps/secrets stack (§3).
4. `./lab cluster golden`: per-node tars of managed paths, an etcd snapshot and gw data, all **kept on the
   desktop** (`.state/golden/`), never on the nodes for you to find.
5. Once: you run `k8slab.bat snapshot baseline`, the manual panic button.

### 2.4 Reset ladder (in-guest; `./lab` has no hypervisor access)

| Level | Used for | Mechanism | Target |
|---|---|---|---|
| ns | ~70% of scenarios | Delete objects/namespaces labelled `lab.scenario=<id>` and the scenario's Argo CD apps; Gitea `baseline` → `main`; restore the OpenBao kv | 5-20 s |
| node | Node/runtime faults | Push the golden tar; undo nft `lab_fault`, tc, sysctls, swap, modules, SIGSTOP and clock; restart containerd + kubelet | 15-40 s |
| cluster | Control plane, etcd, certs, gw | Node reset everywhere + `etcdutl snapshot restore` + restart the control plane and kubelets + gw data + `doctor` | 2-3 min |
| rebuild | Version switch (upgrade scenarios start at 1.36), anything worse | `kubeadm reset` + build + golden | ~10 min |
| vm (manual) | SSH gone | `k8slab.bat restore baseline`, then `./lab vm wait` | ~3 min |

Faults that would need a hypervisor are done in the guest:
- **Partition**: nft drops cluster peers but keeps ssh from 192.168.56.1, the desktop as seen through the host.
- **Kubelet hang**: SIGSTOP.
- **Slow node**: CPUQuota on `kubepods.slice`.
- **Flaky link**: tc netem.
- **Internet loss**: nft drop on the NAT NIC.
- **Reboot-surfacing faults**: swap, modules, fstab.
- **Clock skew**: `date -s` with chrony stopped.
- **Expired certs**: short-lived kubeadm certs.

## 3. GitOps and secrets stack (in the golden baseline)

- **Gitea** on gw hosts `lab/gitops` (`apps/`, `projects/`, `charts/`, `envs/{dev,prod}`, `secrets/`).
  - Tag `baseline` is the reset point.
  - The student works in `workspace/gitops` and pushes fixes.
- **Helm charts**:
  - `charts/labapp`: Deployment, Service, Ingress/HTTPRoute, ConfigMap, SA, HPA, PDB, NetworkPolicy toggles;
    secret from an existing Secret, a SealedSecret or an ExternalSecret.
  - `charts/shop`: an umbrella chart (frontend, api, redis, postgres; vendored subcharts).
- **Argo CD** manages only lab apps. Addons stay under `./lab`/Helm, so self-heal never fights scenario faults.
- **Sealed Secrets** in kube-system. The key is backed up to `.state/` for the DR scenarios.
- **ESO + OpenBao** (MPL fork of Vault):
  - OpenBao: TLS from the lab CA, a 1-of-1 unseal key in `.state` (`./lab` unseals after boot), kubernetes auth
    with one role per namespace, kv-v2;
  - stores use `caProvider`.
- **SOPS + age** on the desktop: a learn lab + 2 incidents. Argo CD CMP/KSOPS is a wave-3 candidate.

## 4. Framework

The `ansible-lab` skeleton: list, start, ticket, hint, verify, diff, solution, solve, reset, selftest,
interview, status.

| Area | Commands / helpers |
|---|---|
| `./lab vm` (built) | `check`, `kit`, `seedtest`, `wait`, `status`, `soak [min]`; `./lab node <n>` |
| `./lab vm` (Phase 1) | `provision` |
| `./lab cluster` (Phase 1) | `build`, `golden`, `reset`, `rebuild`, `doctor` |
| Other commands | `./lab env` (PATH = `cache/bin`, KUBECONFIG), `./lab ui`, `./lab chaos`, `./lab exam` |
| Scenario helpers | `kx` (local kubectl), `nx <node> '<cmd>'` (root on a node), `nssh`, `gx` (Gitea), `bx` (bao), `fault_partition`, `fault_clear`, `wait_rollout`, `incluster_curl`, `can_i`, `argo_status`, `curl_matrix` |

Scenario layout:
- files: `scenario.yaml`, `ticket.md` (**Test** line), `hints.md` (3 hints), `manifests/`,
  hidden `.lab/{setup,verify,solve}.sh` + `solution.md`;
- `scenario.yaml` adds `reset: ns|node|cluster|rebuild`, `version`, `nodes`.

## 5. Content

| Domain | IDs | Notes |
|---|---|---|
| P Pods & containers | P01-P16 | |
| C Configuration | C01-C08 | |
| S Scheduling | S01-S14 | |
| R Resources & autoscaling | R01-R10 | |
| W Workload controllers | W01-W12 | |
| N Services & DNS | N01-N14 | |
| G Ingress & Gateway API | G01-G08 | |
| X NetworkPolicy & CNI | X01-X10 | +X09 default-deny blocks DNS and ESO→OpenBao, +X10 Argo CD egress |
| V Storage | V01-V10 | |
| A Security | A01-A13 | +A12 API secret read Forbidden, +A13 audit "who read the secret" |
| K Control plane | K01-K17 | +K13 kubeadm upgrade (was O12), haproxy LB, w4 join, EncryptionConfiguration, SAN |
| L Nodes & runtime | L01-L18 | +partition/StatefulSet, tolerationSeconds, slow node, swap, `br_netfilter`, clock, `/var` full, conntrack |
| O Cluster operations | O01-O11 | |
| Q Observability | Q01-Q05 | |
| **D Delivery (Helm & Argo CD)** | D01-D12 | Values typo, drift, bad auto-sync, AppProject deny, repo creds, HPA OutOfSync, immutable selector, rollback vs self-heal, hook stuck, valueFiles order, app-of-apps, prune deleted a PVC |
| **Y Secrets** | Y01-Y10 | SealedSecret scope, lost sealing key, ESO path / role / CA, OpenBao sealed, rotation vs env, ownership fight, SOPS updatekeys, SOPS plaintext leak |
| B Boss fights | B01-B07 | +B07 GitOps DR |
| **T Learn track** | T01-T16 | Lab tour, kubeadm anatomy, join w4, packet path, storage, MetalLB/Gateway, RBAC/CSR, etcd backup, upgrade, Helm, Argo CD, Sealed Secrets, ESO+OpenBao, SOPS, NetworkPolicy for GitOps, hardening |

~195 incidents + 16 learn labs. The research report's 8 scenarios are D01, D02, D03, D04, Y01, Y03, A12 and
X09, all in wave 1.

## 6. Build plan

| Phase | Deliverable | Gate |
|---|---|---|
| **0 Kit + spike** | Kit, seed, `./lab vm kit/seedtest/wait/status`; you run `k8slab.bat create gw cp1` | Correct hostname + IP; SSH from the desktop; each VM has its own disk cloned from one base; kit `snapshot`/`restore` work; 30-min soak with no VirtualBox halt; NEM status known |
| **1 Fleet + cluster** | All 5 VMs, provision, 1.36 → 1.37, addons, `doctor`, `golden` | Doctor green. Broken apiserver, etcd and kubelet all come back via `cluster reset` in ≤3 min. Doctor green with NAT egress dropped. 2-h soak within budget |
| **2 GitOps + secrets** | Gitea, charts, Argo CD, Sealed Secrets, ESO + OpenBao | labapp Synced/Healthy with 1 SealedSecret + 1 ExternalSecret; survives `cluster reset` |
| **3 Framework** | CLI, helpers, reset ladder, 4 pilots (ns/node/cluster/GitOps) | Pilots pass selftest twice in a row |
| **4 Learn** | T01-T16 | selftest green |
| **5 Wave 1** (~60) | P/S/N/V/A basics, K01-K04, L01-L06, L11-L14, the 8 research scenarios | selftest green |
| **6 Wave 2** (~75) | C, R, W, G, X, O, rest of K/L/D/Y | selftest green |
| **7 Wave 3** (~45) | Level 3, B01-B07, interview/exam/chaos | Full selftest within a night |
| **8 Docs** | README, CATALOG final, FAULTS.md, INTERVIEW-QUESTIONS, root README | - |

## 7. Budgets

| Resource | Budget |
|---|---|
| RAM | 19 GB of the ~32 GB free (+2 GB with w4) |
| vCPU | 9 + desktop 8 = 17 on 16 threads. Mild overcommit; the soak decides whether the desktop drops to 6 |
| Windows disk | ~40 GB (base ~2.5, a full clone per VM ~2.5 + growth ~3-4 each, gw data ~3); `check` warns below 50 GB free |
| Desktop disk | ≤1.5 GB of the 12 GB free (CLIs, charts, golden ~0.3 GB) |
| Downloads | ~5 GB once, fetched by gw and shared with the nodes |

## 8. Risks

| Risk | Mitigation |
|---|---|
| VirtualBox disk/snapshot semantics | Phase 0 gate. Multiattach was dropped after the first Windows runs; full per-VM clones are used instead |
| etcd-restore reset leaves stale state | `doctor` after each reset; cluster-level scenarios selftested twice; fallback `rebuild` |
| The `.bat` can't be tested on this Linux desktop | Kept plain and identical in logic to the shellchecked `.sh` twin; `check` first; Phase 0 runs it for real |
| VirtualBox on the Windows hypervisor (NEM, "turtle") | `check` warns; turning off Hyper-V/VBS is your call |
| CPU overcommit | Soak gates; desktop to 6 vCPU |
| Upstream drift | Everything pinned in `versions.env`; `./lab selftest all` after bumps |

---

## 9. History and phase results

### Phase 0 v1 (2026-11-04): nested virtualization is NOT viable here
- `qemu -enable-kvm` inside this desktop VM halted VirtualBox at once.
- `lscpu` said "KVM" only because VirtualBox exposes a KVM paravirt interface; the machine is a VirtualBox 7.0
  guest, and KVM-in-VirtualBox means nested AMD-V.
- The two earlier freezes ended the same way: the journal stops with no shutdown record.
- Options considered: kind in this VM, a sibling VM running kind, cluster outside VirtualBox, k3s.

Settled on 2026-11-08 by the v2 decisions above.

### Phase 0 v2 (2026-11-08): kit built, seed verified
- `infra/vbox/` written:
  - `nodes.csv`;
  - `k8slab.sh` (shellcheck clean, bash 3.2 compatible for macOS);
  - `k8slab.bat` (CRLF, same logic; not executable here, so first real run is on Windows);
  - `README.md`.
- `tools/mkseed.py` + `infra/cloud-init/` written; pycdlib 1.22.0 is imported from its wheel.
- **Seed verified**: release 20261017 booted under QEMU/TCG (software emulation, no `/dev/kvm`) as `k8s-cp1`.
  - About 3 min to cloud-init `done`.
  - SSH as `lab` with the desktop key, passwordless sudo.
  - Hostname and `/etc/hosts` set; 192.168.56.21/24 on the host-only NIC.
  - NAT NIC on DHCP with the default route.
  - The interface names were `ens3`/`ens8` (MAC matching made that irrelevant).
- kind tooling removed: `infra/kind`, `provision.sh`, `lib/remote.sh`, the kind binary.
- **First Windows run (VirtualBox 7.2.20)**: `check` passed (host-only adapter found, 254 GB free).
  `create` downloaded and verified the image, then failed. VirtualBox refuses `--type multiattach` on a disk
  in its global media registry, which is where `clonemedium` puts it. Fixes in both scripts:
  - `closemedium` the base, then let the first `storageattach --mtype multiattach` set the type;
  - 7.1+ `createvm` requires `--platform-architecture x86`;
  - a failed create now deletes the half-made VM.
- **Second run**: `createvm` failed with access denied. VirtualBox's default machine folder pointed into another
  Windows profile (`C:\Users\evrod\...`). The VMs now go to `%K8SLAB_HOME%\vms` via `--basefolder`;
  VirtualBox's default folder is never used.
- **Third run**: `storageattach --mtype multiattach` hit the same global-registry error even after
  `closemedium`: on 7.2, reopening a disk puts it straight back into the global registry.
  **Multiattach dropped**: every VM now gets a full `clonemedium` copy of the base in
  `%K8SLAB_HOME%\disks\` (~2-3 GB each at first).
- **Fourth run**: `k8slab.bat create` created and started all 5 VMs (gw, cp1, w1-w3). The `.bat` works end to end
  on VirtualBox 7.2.20.
- **2026-11-09, VMs verified from the desktop**: `./lab vm wait` passed on all 5 VMs (SSH, hostname, static IP,
  cloud-init done).
  - The desktop VM needs **no host-only NIC**: its NAT traffic to 192.168.56.0/24 is routed by the Windows host,
    so the nodes see it as 192.168.56.1. `vm check` now tests reachability; the partition fault must allow .1.
  - Per VM: CPU and RAM as in `nodes.csv`, 40 GB disk (1.7 GB used), no swap, boot 7-9 s, NTP in sync, no failed
    units, no `/dev/kvm`. NIC names are `enp0s3`/`enp0s8`; node-to-node RTT 0.5 ms.
  - `k8slab.bat check` gave no Windows-hypervisor warning, so VirtualBox isn't on NEM.
  - Fixed: `./lab vm status` stopped after the first node (ssh read the loop's stdin).
- **Soak passed (2026-11-09, 10:21-10:51)**: `./lab vm soak 30` ran for 30 min, with load on all 5 VMs at once:
  - CPU at half of every VM's vCPUs, a quarter of its RAM held, 256 MB direct disk writes every 30 s;
  - 52 probes per node: 0 missed, 0 reboots, load active throughout (max load 1.2-2.6);
  - desktop VM: max load 0.79, ≥16.9 GB available, journal never stopped, gw ping never down;
  - no VirtualBox halt.
- **Snapshot round trip passed (2026-11-09)**: `k8slab.bat snapshot spike` ran on all 5 VMs (clean ACPI
  shutdown each time). A flushed marker `/home/lab/after-snapshot` was written on cp1 at 11:01:01. After
  `k8slab.bat restore spike`, all VMs rebooted (cp1 at 11:01:34) and the marker was gone. (`/tmp` is no
  proof: Ubuntu empties it at boot.)
- **Phase 0 gate: PASSED (2026-11-09).** Next: Phase 1 - pin versions, `./lab vm provision`, kubeadm 1.36 →
  1.37, addons, `cluster doctor/golden`.

### Phase 1 (2026-11-09)

- **Pins**: k8s 1.36.5 → 1.37.1 (1.36.6/1.37.2 were only 12 days old), containerd 2.4.2, runc 1.5.2, Calico 3.33.0
  (tested on 1.35-1.37), MetalLB chart 0.16.1, Traefik chart 42.1.3, metrics-server chart 3.14.0, Gateway API
  1.6.3, local-path 0.0.37, csi-driver-nfs 4.13.6, snapshotter 8.7.0, registry 3.1.2, crane 0.22.1, helm 4.3.1.
  19 files in `infra/artifacts.txt`, 30 images in `infra/images.txt`.
- **1a gw**: Docker-free; first sync ~5 min.
  - Registry with 30 images (24 repos), flat apt repo with both minors (141 MB), 19 verified files.
  - haproxy, chrony, NFS and nginx all up; gw uses 3.5 GB disk and 400 MB RAM.
- **1b nodes**: all 4 in ~2 min.
  - containerd mirrors (`override_path`); packages held; chrony from gw; 16 images pre-pulled.
  - With NAT egress dropped, every node pulls from registry.k8s.io, quay.io and docker.io through gw.
- **1c build at 1.36.5**: `./lab cluster build` ~5 min; doctor PASS on all 19 checks. That includes the desktop
  reaching NodePorts, the MetalLB LB IP, Ingress and an HTTPRoute through NAT → Windows → host-only.
- **1d**:
  - `cluster upgrade 1.37` → v1.37.1 (etcd 3.6.8 → 3.7.0). First run: `uncordon` hit the API restart window
    (static pods recreated by the new kubelet; brief Forbidden). Fixed with retries; the upgrade resumes.
  - Golden: 27 MB, etcd snapshot of 1,227 keys.
  - `cluster reset` brought back each fault twice, every time with doctor PASS:
    - apiserver bad flag: 22 / 23 s;
    - etcd data-dir moved (cluster looked empty): 27 / 22 s;
    - kubelet disabled on w2: 23 / 31 s;
    - rogue static pod: 27 / 28 s;
    - `reset node w2`: 10 s.
  - Offline doctor PASS, after fixing `vm offline`: an OUTPUT-hook `oifname` rule dropped the nodes' own
    traffic to 10.96.0.1 (oifname is pre-DNAT-reroute), so Calico CNI failed. Now matched in POSTROUTING.
- **1e**:
  - `k8slab.bat snapshot baseline` was taken (12:25). It shut down all VMs cleanly, with the soak only 2.5 min
    in, so that soak is void. Nothing from it ended up in the snapshot (no `/var/tmp` leftovers).
  - **Cold boot of all VMs → doctor PASS** without any reset, so the baseline snapshot holds a healthy
    v1.37.1 cluster.
  - **2-h soak skipped (decision, 2026-11-09).** The evidence so far:
    - the 30-min Phase 0 soak under load;
    - ~1.5 h of bursty cluster work with no halt (build, upgrade, 10 resets, offline doctor, cold boot);
    - `k8slab.bat check` showed no Windows hypervisor (NEM).

    Run `./lab vm soak 120` before the first overnight selftest, or as soon as a VirtualBox halt shows up.
- **Phase 1: DONE (2026-11-09).** Baseline: v1.37.1, golden in `.state/golden`, `baseline` snapshot on the host.
  Next: Phase 2 - GitOps + secrets (Gitea, Argo CD, Sealed Secrets, ESO + OpenBao, charts), then a new golden.

### Phase 2 (2026-11-09): GitOps + secrets

- **Pins**: Argo CD 3.5.6 (chart 10.11.6), Sealed Secrets 0.41.2 (chart 2.22.0), ESO 2.14.0, OpenBao 2.7.2, Gitea
  28.2.0, SOPS 3.13.3, age 1.3.2, `lab/redis` (7.4.11-alpine), `lab/postgres` (16.14-alpine). Totals: 28 artifacts,
  41 images, 5 labapp tags.
- **2a gw**:
  - OpenBao uses raft storage: 2.7 has no `file` backend and no `disable_mlock`.
  - TLS from a lab CA; static-key auto-unseal, unsealed by itself after a gw reboot.
  - Gitea: SQLite, offline, repo `lab/gitops`.
  - The first init lost the one-time root token to a 5-s client timeout. Init now waits up to 180 s, and
    `--reset-openbao` exists for exactly that case.
- **2b**: `./lab images build` (docker save → crane push on gw).
- **2c**: `./lab gitops stack`:
  - CoreDNS `lab` zone;
  - Sealed Secrets (key + cert backed up);
  - ESO with OpenBao kubernetes auth: store Ready on the first try;
  - Argo CD on .201.
- **2d**: `./lab gitops seed`. demo (SealedSecret) and shop (ExternalSecret) are Synced + Healthy, and doctor PASS
  with 31 checks (12 new for GitOps & secrets: shop end to end, demo 401/200, ...). Two fixes on the way:
  - Pods hit ImagePullBackOff: containerd needs a `certs.d/registry.lab:5000` hosts.toml for the plain-HTTP lab
    registry.
  - Node provisioning's "joined node keeps its packages" guard checked `admin.conf` (cp only). A re-provision
    would have downgraded the workers to 1.36.5; it now checks `kubelet.conf`.
- **2e**:
  - New golden: 36 MB, gw part with Gitea + OpenBao data.
  - `cluster reset` → doctor PASS in 56 s. The first reset took 170 s: approved CSRs are garbage-collected after
    1 h, so "wait until every node has an approved serving cert" ran out its timeout. A reset now only approves
    pending CSRs.
  - Offline doctor PASS.
  - `baseline` snapshot retaken (14:35) → cold boot → doctor PASS incl. GitOps, so the snapshot holds Phase 2.
    On k8s-gw, deleting the old `baseline` failed ("disk locked by another task", right after the power-off),
    and the kit took the new one anyway, which leaves 2 snapshots named `baseline` there. Fixed in the kit: every
    same-named snapshot is deleted first, with retries, and nothing is taken if that fails.
    To clean up: `k8slab.bat snapshot baseline gw`.
- **Phase 2: DONE (2026-11-09).** Next: Phase 3 - the scenario framework (start/verify/hint/solve/
  selftest, reset ladder per scenario) and 4 pilots.

### Phase 3 (2026-11-09): scenario framework + 4 pilots

- **Framework** (`lib/scenario.sh`, `lab`), in the house style of ansible-lab:
  - commands: `list`, `start`, `ticket`, `hint`, `verify`, `solution`, `solve`, `reset`, `stop`, `status`,
    `diff`, `selftest <id..|pilots|waveN|learn|all>`;
  - `workspace/<ID>/` holds the "as found" git copy, `workspace/gitops` the student's clone.
  - Selftest result lines are appended to `.state/selftest.log` as they happen.
  - Helpers, all documented in [docs/FAULTS.md](docs/FAULTS.md):
    - `kns`/`ka`: everything labelled `lab.k8slab/scenario=<ID>`;
    - `http_code`/`http_ok` (from inside the cluster), `http_out` (from the desktop);
    - `restarts`/`stable_for`, `can_i`, `fault_partition`/`fault_clear`;
    - `gitops_commit` (as `dev-bob`), `argo_refresh`/`argo_sync`.
  - `verify` runs with a 10-s API timeout, so a dead API fails a check instead of hanging it.
- **Reset ladder per scenario** (`scenario.yaml reset:`), run before the next lab starts:
  - `ns`: namespaces + labelled objects;
  - `node`: + golden files/runtime faults on `nodes:`;
  - `gw`: + gw data;
  - `cluster`: etcd restore + every node + gw;
  - `gitops: true` adds: `baseline` → `main`, then Argo CD re-sync until Synced + Healthy.
  - Then `cluster_quick`: API, nodes, system pods, Argo apps. If it fails, `start` escalates to a full
    `cluster reset`.
- **Pilots**:
  - N01 (ns): Service selector vs pod label;
  - L01 (node): kubelet disabled on w2;
  - K01 (cluster): apiserver `--etcd-servers` port typo;
  - D02 (ns + GitOps): drift during a self-heal-off change freeze.
- **Fixes on the way**:
  - `kubectl label --local -o yaml` prints a multi-document file without the `---` separators, so `ka`
    labels with a small Python YAML filter instead.
  - The first selftest died with the desktop: it rebooted at 15:03, and the output in `/tmp` went with it.
    Results now go to `.state/selftest.log` line by line.
  - D02 showed `fixed:NOT FIXED` on the next run. Its reference fix synced the app, but the hand-added env var
    `GREETING` was still there, and Argo CD reported Synced + Healthy. A field Git never declared is not
    drift for the three-way merge, so neither a sync nor self-heal removes it. That is now the scenario's
    second layer: the student has to find and remove it. Hint 3, the solution and solve.sh were updated.
- **Timings** (3 full runs; each lab's time includes the cleanup of the lab before it):
  - D02 18-30 s;
  - K01 55-68 s;
  - L01 223-240 s (K01's cleanup is a `cluster reset` + doctor, ≈ 2 min);
  - N01 50-169 s (L01's node reset, then a fresh namespace and image pulls);
  - a whole pilot run takes 6-8.5 min.
- **Gate: PASSED.**
  - After the D02 fix, `./lab selftest pilots` passed twice in a row: 16:40-16:48 and 16:48-16:54 UTC, all 4
    `broken:ok fixed:ok`.
  - Then `./lab cluster doctor` PASS (38 s); `./lab status` → none.
  - The reset levels ns, ns + GitOps, node and cluster all ran between the runs (no pilot uses `gw`).
- **Phase 3: DONE (2026-11-09).** Next: Phase 4, the learn track (T01-T16, `learn/`). These framework gaps
  surfaced in review and are needed by wave 1/2:
  - an ns-level OpenBao kv restore, for the Y scenarios;
  - a `rebuild` reset level and a `version:` key, for K13 (upgrade from 1.36);
  - a `curl_matrix` helper, for the X scenarios;
  - CATALOG rows still say `labapp`, `envs/dev|prod` and `payments`, but the live repo has `demo`/`shop` and
    `envs/<app>`;
  - PLAN §2.1/§2.3 still describe docker-ce, dnsmasq and apt-cacher-ng; the gw is Docker-free (nginx, CoreDNS
    `lab` zone).

### Phase 4 (2026-11-09): the learn track T01-T16

- **16 guided labs** in `learn/` (`kind: learn`), the ansible-lab learn style:
  - numbered steps, a **Test** line, 3 hints that give the commands;
  - `solution.md` with takeaways;
  - the same `start/verify/solve/selftest` as the incidents (verify must FAIL before the work).
- **T01-T08**:
  - T01 lab tour;
  - T02 kubeadm anatomy;
  - T03 joins **k8s-w3** back by hand (your decision: no w4 VM). It teaches the `--node-ip` NAT trap and the
    serving CSR;
  - T04 packet path;
  - T05 storage (local-path, NFS RWX, snapshot restore, Retain);
  - T06 MetalLB / Ingress / Gateway;
  - T07 RBAC + CSR users;
  - T08 etcd backup/restore.
- **T09-T16**:
  - T09 kubeadm upgrade, from a bare 1.36 cluster;
  - T10 Helm (failed release, rollback, release Secrets);
  - T11 Argo CD (app-of-apps, AppProject, self-heal);
  - T12 Sealed Secrets (key-loss drill);
  - T13 ESO + OpenBao (least-privilege role, caProvider, rotation);
  - T14 SOPS + age (updatekeys, no plaintext in history);
  - T15 NetworkPolicy for the GitOps stack (the API's post-DNAT endpoint);
  - T16 hardening (encryption at rest, audit, PSA).
- **Framework additions**:
  - `answer`/`answered`: `answers.yaml` checked against live truth from `.lab/facts.sh`;
  - an optional `.lab/cleanup.sh` hook;
  - `tcp_ok_as`/`check_reach`;
  - `cluster_bare_build <version>`;
  - `./lab ui`;
  - `./lab env` exports for bao, sops and argocd;
  - the GitOps reset runs **before** namespace deletion (otherwise a self-healing app re-creates its
    namespace) and removes non-baseline Applications/AppProjects;
  - "as found" is committed after setup.

  This closes 2 Phase 3 gaps (`curl_matrix` → `check_reach`; `rebuild`/`version:` → `cluster_bare_build` +
  `reset: cluster`). The ns-level OpenBao kv restore is still open: T13 uses `reset: gw`.
- **Fixes on the way**:
  - T08's first restore proof was the etcd cluster ID. A proper restore keeps the ID, because it derives from
    the member name, peer URL and token. The proof is now a new member dir (inode).
  - `ls -A` counted the kubelet package's hidden `.kubelet-keep` in the manifests dir. kubelet skips hidden
    files.
  - `cluster_bare_build` first kept cp1's kubeconfigs too. kubeadm init then tries to create the
    admin.conf ClusterRoleBinding before the API is up, and fails. Now only the PKI is kept.
  - The cluster reset after that failed build brought the cluster back cleanly: a good test of the reset
    ladder.
- **Timings** (gate runs; each lab's time includes the cleanup of the lab before it):
  - T01 17 s, T02 22 s, T07 20 s, T11 32-36 s, T14 20 s, T15 31 s;
  - T03 85 s, T04 93-106 s (after T03's cluster reset), T05 58-60 s, T06 81 s, T08 121 s;
  - T09 485-516 s (bare build ≈ 4 min + upgrade ≈ 3-4 min);
  - T10 176-180 s (after T09's cluster reset), T12 67 s, T13 118-128 s, T16 152-165 s;
  - **a whole learn run takes ≈ 29 min**.
- **Gate: PASSED.**
  - `./lab selftest learn` passed twice in a row: 17:58-18:26 and 18:26-18:55 UTC, 16/16 `broken:ok fixed:ok`
    both times.
  - Then `./lab selftest pilots` 4/4 (regression, incl. D02 with the new GitOps cleanup order) and
    `./lab cluster doctor` PASS.
- **Phase 4: DONE (2026-11-09).** Next: Phase 5, wave 1 (~60 incidents, including the research doc's 8:
  D01, D03, D04, Y01, Y03, A12, X09 + D02 done). Open gaps carried over:
  - an ns-level OpenBao kv restore, needed by the Y scenarios;
  - the CATALOG app names (`labapp`/`envs/dev|prod`/`payments`) vs the live repo (`demo`/`shop`);
  - the PLAN §2 gw description (docker/dnsmasq/apt-cacher-ng) vs the real Docker-free gw.

### Phase 5 (2026-11-10/11): wave 1 - 61 incidents

- **61 incidents** with `wave: 1`, all in the pilot pattern: the reporter's ticket, an outcome verify with
  "don't cheat" guards, 3 hints, a solution with interview notes. 57 are new, plus the 4 pilots.
  - 5a research (D01, D03, D04, Y01, Y03, A12, X09) - commit 877ac0d;
  - 5b control plane + nodes (K02-K04, L02-L06, L11-L14) - commit 3fa401b;
  - 5c pods + scheduling (P01, P04, P06-P12, S01-S04, S06-S09, S11) - commit b39eb7b;
  - 5d services, storage, security (N02-N07, N09, N14, V01-V04, V08-V10, A01-A03, A05, A06) - commit 965b4e5.
  - Moved to wave 2: V05 (local-path volumes are hostPath, so there is no fsGroup to teach), P02 (needs an
    htpasswd registry), P03 (needs an arm64 image), the second-tier level-2 rows.
  - The CATALOG D/Y rows now name the live repo (`demo`, `shop`, `envs/<app>`), and each row's verify column
    says what the verify script checks.
- **Framework**:
  - `openbao: true`: `cluster golden` saves an OpenBao raft snapshot; the cleanup restores it in ~7 s (same
    root token, ESO recovers by itself). T13 moved from `reset: gw` to `ns` + `openbao`. This closes the
    Phase 4 gap.
  - every cleanup normalizes the Node objects: uncordon, zone labels, lab taints;
  - helpers `deploy_ready`, `has_endpoints`; the node reset also undoes kubepods.slice drop-ins and swap;
  - the GitOps reset deletes extra Applications first, and strips the finalizer of an app whose AppProject is
    gone. Argo CD can't finalize such an app ("error getting app project"), and lab-apps' prune deletes
    both at once. D04's cleanup went from 71 s to 12 s, and it no longer escalates to a cluster reset;
  - a node-level cleanup resets the nodes *before* it waits for the namespaces: pods on a partitioned node
    can't finish terminating (L11/L12 each lost 120 s);
  - setup/solve print the failing line of a `set -e` script (ERR trap); selftest keeps a failed setup's log
    as `.state/selftest-setup-<ID>.log`;
  - `stable_for` also fails on a restart within its look-back window. A pod killed every ~40 s is Ready
    between the kills, and the broken pass only watches for 3 s (P09 was NOT BROKEN);
  - `crashlooping`: CrashLoopBackOff, or at least 2 restarts after a failure. Polling only the waiting reason
    misses it, because between restarts the state is running or terminated (P04's setup timed out once).
- **Infra**: a host sleep left the paused VMs 18.6 h behind, and chrony's default `makestep 1 3` only slews.
  gw and the nodes now use `makestep 1 -1`, in provisioning and in the golden. Ping from the desktop never
  works (the route goes through VirtualBox NAT): `./lab vm status` is the check.
- **Fixes on the way**:
  - D04: Argo CD 3.5 reports a destination denial as "do not match any of the allowed destinations";
    "not permitted" is the repo/resource-kind check. The T11 hint quoted the old text.
  - L06: without `--node-ip` the kubelet resolves its hostname first, and `/etc/hosts` maps it to the
    host-only IP. The fault also needs cloud-init's `127.0.1.1 k8s-w2` (loopback is skipped → the
    default-route NIC, NAT 10.0.2.15).
  - P12: busybox >= 1.29 `nslookup <short name>` exits 1 when any search domain answers NXDOMAIN, even
    though the name resolves, so an `until nslookup` init loop never ends. It now uses `labapp wait-for`.
  - S04: moving away from required anti-affinity deadlocks the rollout. The old pods' anti-affinity is
    symmetric and repels the new pods, and the old ReplicaSet can't shrink below `replicas - maxUnavailable`.
    The fix removes the old ReplicaSet. A `DoNotSchedule` spread also needs `nodeTaintsPolicy: Honor`,
    otherwise the tainted cp1 counts as an empty domain.
  - A02: `kubectl auth can-i create pods/exec` reads `<resource>/<name>` and asks about a pod *named* exec
    (and `get pods/log` said yes for anyone who may get pods). Subresources need `--subresource=exec`.
  - A03: the API server pretty-prints JSON for curl/wget user agents (`"kind": "PodList"`). busybox 1.37
    `wget` does https (it ships `ssl_client`).
- **First batch runs**: 5a 6/7 (D04), 5b 11/12 (L06), 5c 15/18 (P09, P12, S04), 5d 18/20 (A02, A03). Every
  failure was a scenario or framework bug, fixed and rerun green.
- **Per-batch timings** (each lab's time includes the cleanup of the lab before it):
  - most ns-level labs take 15-60 s;
  - probe/restart labs take 100-280 s (P04, P08, P09, P11, A06: a 60 s stability window);
  - node labs take 75-300 s (L13 297 s);
  - K02-K04 take 60-180 s; N06/N07 (cluster reset) take 44-120 s;
  - Y01 took 514 s once, when D04's leftover forced a cluster reset (fixed).
- **Gate: PASSED (2026-11-11)**, after a cold start of all VMs, which doctor passed at once:
  - `./lab selftest wave1` passed twice in a row: 09:44-10:56 and 10:56-12:09 UTC, 61/61 `broken:ok fixed:ok`
    both times, with no fixes in between;
  - then `./lab selftest learn` 16/16 (12:09-12:38; T13 on `reset: ns` + `openbao`, 123 s);
  - then `./lab cluster doctor` PASS.
  - (A first attempt on 2026-11-10 was stopped after 4/61, all green, and deferred to the next day.)
- **Timings** (gate runs; each lab's time includes the cleanup of the lab before it):
  - **a wave1 run takes ≈ 72 min**: 35-36 labs ≤ 60 s, 13-16 take 61-120 s, 10-12 take > 120 s;
  - the slowest: L01 222-233 s, P11 165-192 s, K04 169-181 s, L13 110-172 s, L11 166-170 s, K02 164-169 s,
    L04 143-165 s, X09 154-155 s, S09 149-152 s, L02 149-151 s;
  - D04 now takes 110 s, and Y01 34 s (it took 514 s when D04's leftover forced a cluster reset);
  - a learn run takes ≈ 28-29 min, unchanged from Phase 4.
- **Phase 5: DONE (2026-11-11).** Next: Phase 6, wave 2 (~75: C/R/W/G/X/O, the rest of K/L/D/Y, plus
  P02/P03/V05 and the deferred level-2 rows). Open gap carried over: the PLAN §2 gw description
  (docker/dnsmasq/apt-cacher-ng) vs the real Docker-free gw.
