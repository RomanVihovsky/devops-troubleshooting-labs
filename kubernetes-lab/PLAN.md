# kubernetes-lab - plan (draft for approval)

A local break/fix playground for **Kubernetes troubleshooting** - the CKA "Troubleshooting"
domain (30% of the exam), the scenario questions interviewers ask, and the failure classes
from real postmortems (k8s.af). Same workflow as `../swarm-lab` and `../linux-lab`:

```
./lab start P08        # fresh namespace (or fresh cluster), broken on purpose, ticket printed
./lab sh               # shell in the lab VM: kubectl, k9s, helm, stern, etcdctl...
./lab verify           # PASS / FAIL against the ticket's "Test"
./lab hint | solution | solve
./lab interview        # 3 random tickets, 45-minute timer, scored like a real interview
```

Companion documents:
* [docs/CATALOG.md](docs/CATALOG.md) - **155 scenarios**: symptom, how each is emulated, how it's verified (spoilers!)
* [docs/INTERVIEW-QUESTIONS.md](docs/INTERVIEW-QUESTIONS.md) - **~170 interview questions** with the key points of a good answer

---

## 0. Decisions (questionnaire, 2026-11-04)

| Question | Answer |
|---|---|
| Cluster environment | **Both**: kind inside a KVM VM now (option B); kubeadm-on-3-VMs track later (option C) for upgrades (O12) and per-node-kernel scenarios |
| Build scope | **Waves**: ~50 core scenarios first, self-tested; then waves 2 and 3 |
| VM size | **6 vCPU / 10 GiB RAM / ~15 GB disk**, 4-node cluster (1 control plane + 3 workers) |
| Downloads | **Approved**: ~4-5 GB once into `cache/` and the VM registry; offline afterwards |

## 1. What we're preparing for (research summary)

| Source | What it tells us |
|---|---|
| CKA curriculum (Feb 2025 revision) | Troubleshooting = **30%**, the biggest domain: clusters & nodes, cluster components, resource monitoring, container output streams, services & networking. Revision added Helm, Kustomize, Gateway API, CRDs/operators |
| Killer Shell / Killercoda CKA drills | Broken `kube-apiserver` static-pod manifests (several errors at once, one in `metadata`), broken controller-manager, broken kubelet config |
| Interview guides (techinterview.org, kube-dojo, jorijn.com KB) | Pod states (CrashLoopBackOff, Pending, ImagePullBackOff, OOMKilled, CreateContainerConfigError), node NotReady and **what happens to StatefulSet pods**, probes, `logs --previous`, topology-spread Pending with free capacity |
| k8s.af failure stories | DNS (`ndots:5` multiplying lookups, CoreDNS OOM), conntrack races (5 s DNS delays), CPU-limit throttling, etcd hitting its storage quota, webhooks taking clusters down |

## 2. Environment design

### 2.1 Hard constraints learned on this machine
* Two freezes of your host during linux-lab development: a **privileged** systemd container, and
  **disk-write throttling** on the host's root disk. Kubernetes-in-Docker (kind/k3d/minikube-docker)
  needs exactly that: privileged node containers running systemd + containerd + iptables.
* Your machine is itself a KVM guest **with nested virtualization**: `/dev/kvm` is usable by
  `admin`, `qemu-system-x86_64` is installed, AMD-V is exposed. 8 vCPU, 19 GiB RAM, **18 GB free disk**.
* No passwordless sudo, Docker Hub was flaky earlier, no compose plugin on the host.

### 2.2 Options considered

| Option | Isolation from host | Realism | Cost / complexity | Verdict |
|---|---|---|---|---|
| A. kind/k3d directly on the host | **none** (privileged containers) | good | low | **rejected** - same class of risk that froze the host |
| B. **kind inside one KVM VM** | full (own kernel) | good: kubeadm-built nodes, static pods, systemd kubelet, containerd, etcd, PKI | medium | **recommended** |
| C. kubeadm on 3 KVM VMs | full | best (real per-node kernels, kubeadm upgrades) | high: 3 VMs, L2 networking without root, ~3x RAM/disk | optional later track |

### 2.3 Recommended: kind inside a KVM VM

```
host (your desktop, unprivileged)
│  ./lab  (bash CLI)           .state/kubeconfig -> host kubectl works too
│  qemu-system-x86_64 -enable-kvm  (user process, capped: systemd-run --user -p MemoryMax=11G -p CPUQuota=600%)
│     user-mode NIC: hostfwd 127.0.0.1:2222->22 (ssh), :6443->6443 (API), :8080->80 / :8443->443 (gateway)
│
└── VM "k8slab"  Ubuntu 24.04 cloud image, 6 vCPU, 10 GiB RAM, 40 GiB thin qcow2
     │  docker, kind, kubectl, helm, k9s, kubectx/kubens, stern, jq/yq, etcdctl, crictl
     │  registry:5000 (plain)  + registry-auth:5001 (htpasswd)  <- all lab images, preloaded
     │
     └── kind cluster "lab" (Kubernetes = current CKA minor)          docker network "kind"
          ├─ lab-control-plane   kube-apiserver, etcd, scheduler, controller-manager (static pods)
          ├─ lab-worker          zone=zone-a
          ├─ lab-worker2         zone=zone-a
          └─ lab-worker3         zone=zone-b
          addons: Calico (CNI + NetworkPolicy), CoreDNS, metrics-server, Traefik (Ingress +
                  Gateway API), local-path-provisioner, csi-hostpath (expansion/snapshots)
```

Why this shape:
* **Safety**: everything privileged lives inside the VM's kernel. Worst case the VM hangs and
  `./lab vm kill` stops it; the host only runs one unprivileged QEMU process with a hard
  memory/CPU cap.
* **Realism**: kind nodes are kubeadm clusters - `/etc/kubernetes/manifests`, `/etc/kubernetes/pki`,
  `systemctl status kubelet`, `journalctl -u kubelet`, `crictl ps`, `etcdctl`. `./lab node lab-worker2`
  is the "ssh into the node" of a CKA task.
* **The VM has its own clock** - certificate-expiry scenarios can move time safely (impossible
  in containers on the host).
* **Offline after the first build** - images live in the VM's registry and in the golden disk.

### 2.4 Provisioning (no root needed on the host)
1. Download the Ubuntu 24.04 cloud image once into `cache/` (~600 MB).
2. cloud-init **NoCloud over HTTP**: the lab serves `user-data` from `127.0.0.1` with Python;
   QEMU passes `-smbios type=1,serial=ds=nocloud;s=http://10.0.2.2:<port>/` (no ISO tools needed).
3. First boot installs packages + tools, pulls/builds all images into the in-VM registry,
   creates the baseline cluster, runs smoke tests.
4. Shut down -> `golden.qcow2` (read-only backing file). Daily work happens in `work.qcow2`, an
   overlay on top of it.

### 2.5 Reset strategy (fast and clean)

| Level | Used for | How | Time |
|---|---|---|---|
| namespace | ~75% of scenarios (pods, services, config, RBAC, storage...) | delete scenario namespaces + cluster objects labelled `lab.scenario=<id>`, restore baseline addons if touched | 5-20 s |
| cluster | control-plane, node, CNI, etcd, cert scenarios | `kind delete` + `kind create` from preloaded images + addons | ~2 min |
| VM | anything weird, clock changes | throw away `work.qcow2`, new overlay on `golden.qcow2`, boot | ~1-2 min |

Each scenario declares its level in `scenario.yaml`; `./lab start` picks it.

### 2.6 Scenario layout (same idea as the other labs)
```
scenarios/P08-oomkilled/
  scenario.yaml     id, title, level (1-3), domain, reset: namespace|cluster, needs: [metrics, gateway...]
  ticket.md         symptoms + **Test** line
  hints.md          3 progressive hints
  manifests/        kustomize base deployed by setup (copied to ~/workspace in the VM for you to edit)
  .lab/setup.sh     kubectl apply + fault injection (kubectl / docker exec into nodes / VM)
  .lab/verify.sh    checks: rollout status, endpoints, in-cluster curl, events, RBAC can-i...
  .lab/solve.sh     reference fix (used by selftest)
  .lab/solution.md  root cause, diagnosis commands, fix, interview notes
```
Scripts run on the host and execute inside the VM over SSH (`kx` = kubectl in VM, `nx <node>` =
shell in a kind node). Nothing from setup is left inside the cluster for you to find.

### 2.7 The lab app
One small image `registry:5000/labapp` (stdlib Python, like the webapp in swarm-lab) with
behaviour switches that look like normal settings: crash on missing env, slow start, memory
leak, CPU burn, log-to-file, readiness/liveness endpoints, DB/redis dependency, big responses,
SIGTERM handling. Plus `netshoot`, `busybox`, `nginx`, `redis`, `postgres`, `curl` images.

### 2.8 Budgets on this machine

| Resource | Budget | Notes |
|---|---|---|
| CPU | VM 6 vCPU (host keeps 2) | QEMU capped with a user systemd scope |
| RAM | VM 10 GiB (cluster ~4-5 GiB used) | host keeps ~9 GiB |
| Disk | ~15 GB total | cloud image 0.6 + golden ~9 + overlay 2-5 + image cache ~2 (optional). **Only 18 GB free today** |
| Network | ~4-5 GB once | Ubuntu image, apt, binaries, container images (Docker Hub, quay.io, registry.k8s.io, ghcr.io) |

### 2.9 Extras
* `./lab interview [--minutes 45] [--count 3] [--level 2]` - random tickets, timer, score, debrief
* `./lab exam` - CKA-style: 15 tasks, 2 h, weighted score, no hints
* `./lab selftest <id|domain|all>` - every scenario must FAIL after setup and PASS after the reference fix
* `./lab chaos <fault>` - ad-hoc faults on a healthy cluster (kill kubelet, partition a node, delay
  CoreDNS, fill a node disk...) for free-form practice

## 3. Scenario catalog (summary)

155 scenarios in 15 domains - full table with emulation + verification in [docs/CATALOG.md](docs/CATALOG.md).

| Domain | IDs | # | Examples (symptoms) |
|---|---|---|---|
| P - Pods & containers | P01-P16 | 16 | ImagePullBackOff (typo, private registry, wrong arch), CrashLoopBackOff, OOMKilled, probe loops, stuck Terminating, Job + sidecar never finishes |
| C - Configuration | C01-C08 | 8 | ConfigMap change not picked up, subPath never updates, double-base64 secret, mount hides image files |
| S - Scheduling | S01-S14 | 14 | Pending: resources, nodeSelector, taints, anti-affinity, topology spread, cordon, schedulerName typo, nodeName |
| R - Resources & autoscaling | R01-R10 | 10 | HPA `<unknown>`, CPU throttling, QoS evictions, LimitRange rejects, PID limit, DiskPressure |
| W - Workload controllers | W01-W12 | 12 | rollout stuck, selector immutable, StatefulSet ordinal stuck, CronJob suspended, PDB blocks drain |
| N - Services & DNS | N01-N14 | 14 | no endpoints, targetPort, named ports, externalTrafficPolicy, CoreDNS loop, ndots, cross-node VXLAN blocked |
| G - Ingress & Gateway API | G01-G08 | 8 | wrong ingressClass, 503 no endpoints, TLS secret mismatch, HTTPRoute not attached, missing ReferenceGrant |
| X - NetworkPolicy & CNI | X01-X08 | 8 | default-deny kills DNS, port semantics, AND vs OR selectors, calico-node down, IP pool exhausted |
| V - Storage | V01-V10 | 10 | PVC Pending, Released PV, node-affinity conflict, fsGroup, immutable volumeClaimTemplates, pvc-protection |
| A - Security | A01-A11 | 11 | RBAC Forbidden, pods/exec, Pod Security Admission, runAsNonRoot, webhook down, user certs via CSR |
| K - Control plane | K01-K12 | 12 | apiserver manifest typos, scheduler/controller-manager down, etcd down, etcd restore, expired certs, etcd NOSPACE |
| L - Nodes & runtime | L01-L10 | 10 | kubelet stopped, containerd down, cgroup driver mismatch, CNI config missing, wrong node-ip, maxPods |
| O - Cluster operations | O01-O12 | 12 | namespace stuck Terminating, finalizers, removed APIs, Helm pending-upgrade, drain, Kustomize overlay, audit log |
| Q - Observability | Q01-Q05 | 5 | `kubectl top` broken, logs to file, restart forensics, noisy neighbour |
| B - Boss fights | B01-B06 | 6 | 3-4 chained faults: Black Friday outage, control-plane meltdown, namespace onboarding, full DR |

Difficulty: level 1 (single obvious layer, 5-10 min), level 2 (needs the right tool/concept,
10-20 min), level 3 (multi-layer or deep internals, 20-40 min). Roughly 40 / 70 / 45.

## 4. Build plan

| Phase | Deliverable | Gate (must be true before continuing) |
|---|---|---|
| **0. Spike** | Boot one VM with cloud-init over HTTP; SSH; run a 1-node kind cluster inside; watch the host journal | host stays healthy for 30 min under load; VM boot < 2 min; nested KVM performance acceptable |
| **1. Golden VM** | Packages, tools, registries, all images preloaded; baseline 4-node cluster + addons; `golden.qcow2` | full cluster from golden in < 3 min, offline |
| **2. Framework** | `./lab` CLI: vm up/down/reset, start/verify/hint/solution/solve/selftest, interview, chaos; helpers (`kx`, `nx`, `wait_rollout`, `incluster_curl`, `can_i`) | 3 pilot scenarios (one per reset level) pass selftest |
| **3. Wave 1** (~50) | Core interview set: P, S, N, V, A basics + K01-K04 + L01-L04 | selftest green |
| **4. Wave 2** (~60) | C, R, W, G, X, O, rest of K/L | selftest green |
| **5. Wave 3** (~45) | level-3 + boss fights + `interview` / `exam` modes | selftest green; full run < 2.5 h |
| **6. Docs** | README, CATALOG (final), INTERVIEW-QUESTIONS, "build your own scenario" | - |

Each wave ends with `./lab selftest <wave>` (broken -> FAIL, reference fix -> PASS) and a host
health check (journal still writing, load normal).

## 5. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Nested KVM slow / unstable | Phase 0 gate; fall back to fewer workers (1 cp + 2) |
| Disk space (18 GB free) | thin qcow2, single golden image, optional image cache, `./lab vm compact`; ask to free space first |
| Flaky internet during the one-time build | retries per download, prefer quay.io/registry.k8s.io/ghcr.io mirrors, resumable cache in `cache/` |
| Clock-change scenarios (cert expiry) | VM-only, always followed by a VM-level reset |
| Version drift (Kubernetes, Calico, Traefik) | pin every version in `versions.env`; `./lab selftest all` after bumps |
| ingress-nginx retirement (announced Nov 2025, best-effort maintenance until Mar 2026) | use Traefik (supports both Ingress and Gateway API); Gateway API is in the CKA curriculum |
| Scenario relies on timing (HPA, evictions) | generous `check_eventually` windows, deterministic load generators |

---

## 6. Phase 0 result (2026-11-04) - nested virtualization is NOT viable here

**What happened**: `./lab vm up` started QEMU with `-enable-kvm` at 09:23. VirtualBox halted with an
error at once: the QEMU serial console stayed empty (the guest never booted), a key file written
seconds earlier was never flushed (0 bytes), the host journal ends at 09:21:52.

**What we got wrong**: `lscpu` reports `Hypervisor vendor: KVM` because VirtualBox (7.0.18 here)
exposes a KVM *paravirtualization interface*. The machine is a **VirtualBox VM**, and running a
KVM guest inside it means VirtualBox **nested AMD-V** - fragile, and here fatal.

**Consequence**: options B (kind inside a KVM VM) and C (kubeadm on KVM VMs) are off the table
*on this machine*. `./lab vm up` is disabled (needs `LAB_ALLOW_NESTED_KVM=yes`).

**Re-reading the earlier "freezes"**: all three ended the same way - the guest journal stops with no
shutdown record. Two coincided with starting a privileged / disk-throttled container, one with
nested KVM. They may all be VirtualBox halts; the VirtualBox log (`VBox.log`, "Guru Meditation")
would tell us the exact cause.

### Replan options

| | Option | Isolation | Coverage of the 155 scenarios | Risk on this machine |
|---|---|---|---|---|
| R1 | **Harden VirtualBox, then kind directly in this VM** (nested AMD-V off, paravirt "Default", 3D acceleration off; staged spike with the health tripwire: 1 node -> 4 nodes) | container-level (kind nodes are privileged) | ~150 (all but VM-clock and kubeadm-upgrade items) | medium: earlier halts coincided with privileged containers - the spike decides |
| R2 | **Cluster outside VirtualBox on the physical host** (Windows: WSL2 + Docker/kind or Hyper-V VM; macOS: Colima/OrbStack; Linux: KVM VM as designed); `./lab` drives it over SSH | full | 155 (+ kubeadm track) | none for this VM |
| R3 | **Remote Linux box** (cloud VM / spare server with KVM): the original kind-in-VM design unchanged, `./lab` over SSH | full | 155 (+ kubeadm track) | none; costs money / needs internet |
| R4 | **k3s single node natively in this VM** (no containers-as-nodes, no nested virt; you run the installer with sudo) | none (it *is* this VM) | ~105: no multi-node, no kubeadm static-pod control plane (K/L domains mostly lost) | low-medium; modifies this VM's networking (uninstall script available) |

**Recommendation**: first read the `VBox.log` of the crashed run. If the halt is clearly nested-SVM
related -> **R1** (disable nested virtualization in VirtualBox, it isn't needed for kind) with a
cautious spike. If the physical host can run containers or VMs itself -> **R2** is the safest and
fastest long-term home for a 4-node lab.

### Decision after Phase 0 (2026-11-04)
User picked **R1 (hardened VirtualBox + kind)** and offered to create **another VM for SSH access**.
Combined into **R1b: a sibling VirtualBox VM `k8slab`** (Ubuntu Server 24.04, 6 vCPU / 12 GB / 60 GB,
nested AMD-V off, host-only network 192.168.56.0/24) running Docker + kind; the desktop VM keeps
`./lab` and drives it over SSH. Crash isolation without nested virtualization; VirtualBox snapshots
replace the qcow2 golden image. Setup steps: [docs/LAB-VM-SETUP.md](docs/LAB-VM-SETUP.md).
Next: spike = provision over SSH -> 1-node kind + tripwire -> 4 nodes -> 30-min soak -> snapshot.
