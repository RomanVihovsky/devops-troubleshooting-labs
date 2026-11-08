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
├─ desktop VM (Ubuntu)   ./lab, kubectl, helm, argocd, kubeseal, sops+age, bao, k9s, stern
│     ssh lab@192.168.56.x => provisioning, scenarios, resets;  kubectl => https://192.168.56.20:6443
├─ k8s-gw   .20  haproxy :6443 (k8s-api.lab -> cp1), registry :5000 + htpasswd :5001, Gitea :3000,
│               OpenBao :8200 (TLS, lab CA), NFS, dnsmasq (*.lab), chrony, apt-cacher-ng
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
| Ubuntu image | Release VMDK + SHA256 from `versions.env`, downloaded once, converted to one **multiattach** base VDI; each VM gets a differencing disk |
| `seed.iso` | One generic cloud-init NoCloud seed for all VMs, built by `tools/mkseed.py` (pycdlib wheel, no pip/sudo). It holds user `lab` + the desktop's key, and network-config that matches both NICs of every node by MAC. `k8slab-identity` sets the hostname and `/etc/hosts` from the NIC2 MAC |
| Delivery | `./lab vm kit` copies the kit into the VirtualBox shared folder when writable, otherwise leaves it in `.state/kit/` |

### 2.3 Provisioning and baseline (`./lab`, over SSH)

1. `./lab vm wait`: SSH, identity and cloud-init done on every VM.
2. `./lab vm provision`: gw first, then the nodes in parallel through gw's apt cache and registry mirror, so
   internet downloads happen once.
   - gw: docker-ce, apt-cacher-ng, registry (every pinned image copied once), haproxy, dnsmasq, chrony, NFS,
     Gitea, OpenBao.
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
- **Partition**: nft drops cluster peers but keeps ssh from the desktop range.
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
| `./lab vm` (built) | `check`, `kit`, `seedtest`, `wait`, `status`; `./lab node <n>` |
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
| **0 Kit + spike** | Kit, seed, `./lab vm kit/seedtest/wait/status`; you run `k8slab.bat create gw cp1` | Correct hostname + IP; SSH from the desktop; each VM has its own diff disk over one base; kit `snapshot`/`restore` work; 30-min soak with no VirtualBox halt; NEM status known |
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
| Windows disk | ~25 GB (base ~1.5, diffs ~3-4 each, gw data ~3); `check` warns below 35 GB free |
| Desktop disk | ≤1.5 GB of the 12 GB free (CLIs, charts, golden ~0.3 GB) |
| Downloads | ~5 GB once, fetched by gw and shared with the nodes |

## 8. Risks

| Risk | Mitigation |
|---|---|
| Multiattach/snapshot semantics | Phase 0 gate; fallback: a full disk clone per VM (+~3 GB each) |
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
- **Next (you)**:
  1. Adapter 2 = host-only on the desktop VM (HOST-SETUP §1).
  2. `./lab vm kit`.
  3. On Windows: `k8slab.bat check`, then `k8slab.bat create gw cp1`.
  4. `./lab vm wait gw cp1`.
