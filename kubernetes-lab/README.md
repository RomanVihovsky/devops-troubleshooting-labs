# kubernetes-lab

**Kubernetes 1.37 on a real kubeadm cluster**, hands-on and offline: a guided **learn track** (16 labs) and
**195 break/fix incidents** in 17 domains - pods and configuration, scheduling, resources and autoscaling,
workload controllers, Services and DNS, Ingress and Gateway API, NetworkPolicy and Calico, storage, RBAC and
admission, the control plane and etcd, nodes and containerd, upgrades and cluster operations, observability and
audit forensics, **Helm + Argo CD GitOps**, and **secrets** (Sealed Secrets, External Secrets + OpenBao,
SOPS + age) - up to seven multi-fault **boss fights**. `./lab interview`, `./lab exam` (CKA style) and
`./lab chaos` (no ticket at all) put you on the clock.

The cluster is not simulated: five VirtualBox VMs next to your Linux desktop VM, built with kubeadm, real etcd,
real kubelets, Calico VXLAN, haproxy in front of the API server. You get a ticket and a workspace, you work with
`kubectl`, `helm`, `argocd`, `kubeseal`, `bao`, `sops` and SSH on the nodes, and `./lab verify` checks the
**outcome** - pods that really serve, packets that really flow, etcd that really holds encrypted Secrets.

```
VirtualBox host (Windows)        k8slab.bat: create / start / stop / snapshot / restore - the only hypervisor access
│
├── desktop VM (Linux)           ./lab (bash), kubectl & co in cache/bin, .state/ (kubeconfig, golden, credentials)
│        │  SSH + HTTPS only, host-only network 192.168.56.0/24
├── k8s-gw   192.168.56.20       haproxy :6443 (API LB) · registry :5000 / :5001 (htpasswd) · apt repo · Gitea :3000
│                                · OpenBao :8200 · NFS · chrony · the *.lab names
├── k8s-cp1  192.168.56.21       control plane: etcd, kube-apiserver, controller-manager, scheduler (static pods)
├── k8s-w1   192.168.56.31  ┐
├── k8s-w2   192.168.56.32  ├    workers: containerd 2.x, kubelet; zone-a = w1 + w2, zone-b = w3
├── k8s-w3   192.168.56.33  ┘
└── k8s-w4   192.168.56.34       spare (powered off; for join exercises)
In the cluster: Calico (VXLAN), CoreDNS, kube-proxy, metrics-server, MetalLB (192.168.56.200-220), Traefik
(Ingress + Gateway API), local-path + NFS CSI, Argo CD, Sealed Secrets, External Secrets Operator.
```

* Plan, research and design decisions: [PLAN.md](PLAN.md) · How faults are built (+ build your own): [docs/FAULTS.md](docs/FAULTS.md)
* All labs with root causes (**spoilers**): [docs/CATALOG.md](docs/CATALOG.md) · Interview prep: [docs/INTERVIEW-QUESTIONS.md](docs/INTERVIEW-QUESTIONS.md)
* The VMs - one-time setup, the kit, day to day: [docs/HOST-SETUP.md](docs/HOST-SETUP.md)
* Separate from `../linux-lab`, `../swarm-lab`, `../terra-labs`, `../ansible-lab` - own VMs, network and state.

## Requirements

* A **VirtualBox 7** host (Windows tested) with a host-only network owning 192.168.56.1, ~19 GB RAM and 9 vCPU for
  the VMs, ~40 GB disk; nested virtualization is **not** used.
* A Linux desktop VM on the same host-only network: `bash`, `git`, `jq`, `python3` + PyYAML, `curl`, `openssl`,
  `ssh`; Docker only to build the `labapp` image.
* Internet once (Ubuntu image, Kubernetes packages, images, CLIs - about 5 GB, fetched by gw); offline afterwards.

## Setup (once)

```bash
./lab vm kit                     # desktop: build the VirtualBox kit (seed ISO with this VM's SSH key)
```
```bat
k8slab.bat check & k8slab.bat create      :: on the VirtualBox host - 5 VMs, headless
```
```bash
./lab vm wait                    # SSH, hostname, IP, cloud-init on every VM
./lab vm provision gw            # gw: apt repo, registry, haproxy, NFS, chrony, Gitea, OpenBao
./lab vm provision nodes         # nodes: containerd, kubeadm/kubelet 1.36 + 1.37, images
./lab cluster build              # kubeadm 1.36 -> upgrade to 1.37, add-ons
./lab gitops gw && ./lab images build && ./lab gitops stack && ./lab gitops seed
./lab cluster doctor             # 33 end-to-end checks
./lab cluster golden             # the reset baseline, kept on this desktop (.state/golden)
```
```bat
k8slab.bat snapshot baseline     :: the panic button
```
[docs/HOST-SETUP.md](docs/HOST-SETUP.md) has every step in detail.

## Quick start

```bash
./lab list                       # labs, ✔ solved, ▶ running
./lab start T01                  # learn track: the tour
./lab start N01                  # an incident: broken on purpose, the ticket printed
eval "$(./lab env)"              # kubectl, helm, argocd, kubeseal, bao, sops for the lab cluster
./lab node cp1                   # a root shell on a node ("SSH into the node" of a CKA task)
./lab verify                     # PASS / FAIL against the ticket's Test
./lab hint                       # 3 progressive hints;  ./lab solution  when stuck
./lab stop                       # clean up (namespaces, a node, or the whole cluster - per lab)
```
`./lab ui` prints the URLs and credentials (Argo CD, Gitea, OpenBao, the ingress, the registry).
`./lab diff` shows what you changed in `workspace/<ID>/`. GitOps labs work in `workspace/gitops` (a clone of the
in-cluster Gitea repo): commit, push, sync - like a team would.

### Practice modes

```bash
./lab interview [n] [minutes]    # n random incidents (default 3, 15 min each), scored - IDs hidden
./lab exam start [minutes]       # CKA style: 8 incidents, one per domain group, 120 min, pass mark 66 %
./lab chaos start [level]        # something is broken - no ticket. ./lab chaos ticket (-25 %) | reveal | stop
```
Points: interview 10 x level per ticket, exam the ticket's estimated minutes; each hint -20 %, `./lab solution` or
`solve` -> 0. A passing `./lab verify` stops the clock; the clock pauses while a ticket's setup runs. Hidden labs
use `workspace/current/`. Past results: `.state/interviews.log`, `exams.log`, `chaos.log`.

## How to play

* The ticket's **Test** line is the definition of done. Constraints in the ticket ("the PDB stays", "don't turn TLS
  verification off", "Git must not change") are checked too.
* Investigate like on call: `kubectl describe`, events, logs, `crictl`, `journalctl -u kubelet`, `etcdctl`, the
  audit log, Argo CD's app status. The ticket names symptoms, not causes.
* Some labs break the API server itself - then the node is all you have (`./lab node cp1`).
* `./lab verify` judges results from outside: probe pods in other namespaces, load tests, a prober on gw, raw
  etcd reads. Restarting your way to a green check doesn't work when the cause is still there.

<!-- TABLES:BEGIN (python3 tools/tables.py --readme) -->
## Learn track

| ID | Lab | Lvl | Reset |
|---|---|---|---|
| T01 | Lab tour: the kit, ./lab, the nodes, the UIs and the reset ladder | • | ns |
| T02 | kubeadm anatomy: static pods, PKI, kubelet config, kubeadm-config | • | ns |
| T03 | Join a node by hand: token, CA hash, node IP, serving CSR, labels | •• | cluster |
| T04 | Packet path: pod → Service → pod across nodes (Calico VXLAN, kube-proxy, conntrack) | •• | ns |
| T05 | Storage: local-path vs NFS RWX, snapshots, reclaim policy | •• | ns |
| T06 | MetalLB + Ingress + Gateway API: three ways in from outside | • | ns |
| T07 | RBAC + CSR users: a user certificate, a group binding, a ServiceAccount token | •• | ns |
| T08 | etcd backup and restore: snapshot, accident, restore | •• | cluster |
| T09 | kubeadm upgrade: 1.36 → 1.37, control plane first, then node by node | •• | cluster |
| T10 | Helm: chart anatomy, values precedence, upgrade, failed release, rollback | •• | ns |
| T11 | Argo CD: app-of-apps, AppProject, manual vs automated sync, self-heal | •• | ns |
| T12 | Sealed Secrets: scopes, sealing-key backup, key loss and restore | •• | cluster |
| T13 | ESO + OpenBao: kv-v2, a least-privilege role, a SecretStore with caProvider, rotation | ••• | ns |
| T14 | SOPS + age: encrypt in Git, a second recipient, updatekeys, no plaintext in history | •• | ns |
| T15 | NetworkPolicy for a GitOps stack: default deny, DNS, app flows, ESO and Argo CD egress | ••• | cluster |
| T16 | Hardening: encryption at rest, an audit policy, Pod Security Admission | ••• | cluster |

## Incidents (195)

Level • one layer, •• the right concept or tool, ••• several layers or internals. Reset is what the cleanup restores (`ns` seconds, `node` under a minute, `cluster` 1-3 minutes).

### P - Pods & containers (16)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| P01 | catalog release 1.4.0 stuck | • | ns | 1 |
| P02 | vendor-api: ImagePullBackOff from our private registry | •• | ns | 2 |
| P03 | etl 1.6 crash-loops right after the start | •• | ns | 2 |
| P04 | billing crashloops in the cluster, works on my laptop | • | ns | 1 |
| P05 | orders-migrate is in CrashLoopBackOff although it succeeds | •• | ns | 2 |
| P06 | ledger pods stuck in CreateContainerConfigError | • | ns | 1 |
| P07 | reports: RunContainerError since the "production server" change | • | ns | 1 |
| P08 | search-cache restarts every few minutes | • | ns | 1 |
| P09 | profile service restarts all day, logs look fine | • | ns | 1 |
| P10 | quotes: pods Running, 0/1 Ready, nothing reachable | • | ns | 1 |
| P11 | analytics restarts forever since the dataset grew | •• | ns | 1 |
| P12 | orders-api stuck in Init:0/1 | • | ns | 1 |
| P13 | A queue-worker pod has been Terminating for ages | •• | ns | 2 |
| P14 | The nightly report never finishes | ••• | ns | 3 |
| P15 | thumbs pods evicted every few minutes | •• | ns | 2 |
| P16 | Every deploy of checkout-api fails a few checkouts | ••• | ns | 3 |

### C - Configuration (8)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| C01 | The promo greeting didn't change | • | ns | 2 |
| C02 | catalog ignores config changes although it re-reads its file | •• | ns | 2 |
| C03 | cart can't log in to its Redis | •• | ns | 2 |
| C04 | Our nginx crash-loops since we gave it its own nginx.conf | •• | ns | 2 |
| C05 | checkout pods never start: "configmap app-config not found" | • | ns | 2 |
| C06 | Can't switch pricing to USD | •• | ns | 2 |
| C07 | ledger can't call the partner gateway - "works on my machine" | ••• | ns | 3 |
| C08 | inventory can't be deployed: "Unsupported value: status.podIp" | •• | ns | 2 |

### S - Scheduling (14)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| S01 | render workers never start | • | ns | 1 |
| S02 | indexer needs the SSD node - and won't start | • | ns | 1 |
| S03 | etl jobs can't start since the workers were "dedicated to batch" | • | ns | 1 |
| S04 | gateway: scaled to 5 for the sale, only 3 run | •• | ns | 1 |
| S05 | search-api only gets half its replicas | ••• | ns | 3 |
| S06 | nothing new starts since last night's maintenance | • | ns | 1 |
| S07 | ml-api never schedules, not even an error | •• | ns | 1 |
| S08 | legacy-sync stuck Pending, "pinned to w4 like in the runbook" | •• | ns | 1 |
| S09 | no logs from k8s-cp1 | • | ns | 1 |
| S10 | The storefront loses pods every time the batch runs | ••• | ns | 3 |
| S11 | edge-proxy won't start: "free ports" | •• | ns | 1 |
| S12 | New deployments can't schedule anywhere | •• | node | 2 |
| S13 | session-api never schedules | •• | ns | 2 |
| S14 | trainer Pending: Insufficient example.com/gpu | •• | ns | 2 |

### R - Resources & autoscaling (10)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| R01 | The autoscaler did nothing during the load test | •• | ns | 2 |
| R02 | kubectl top: "metrics not available yet" | •• | ns | 2 |
| R03 | quotes is slow, but its CPU is "idle" | •• | ns | 2 |
| R04 | payments-api keeps getting evicted on k8s-w2 | •• | node | 2 |
| R05 | worker has 0 pods, no errors on the pods (there are none) | • | ns | 2 |
| R06 | The new analytics service never starts | •• | ns | 2 |
| R07 | reports-api crashes on k8s-w1 with "can't start new thread" | ••• | node | 3 |
| R08 | DiskPressure on k8s-w3 with a mostly empty disk | •• | node | 2 |
| R09 | catalog-api thrashes between 2 and 6 pods | ••• | ns | 3 |
| R10 | notifier deployed, but no pods appear | • | ns | 2 |

### W - Workload controllers (12)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| W01 | The deploy job has been waiting for 40 minutes | • | ns | 2 |
| W02 | search v2 can't be deployed | •• | ns | 2 |
| W03 | market's web page shows the admin app every other time | •• | ns | 2 |
| W04 | quorum never gets past its first member | •• | ns | 2 |
| W05 | kv members can't find each other | •• | ns | 2 |
| W06 | No logs from k8s-w1 and k8s-w2 | • | ns | 2 |
| W07 | The nightly report job fails | • | ns | 2 |
| W08 | No export for two nights | •• | ns | 2 |
| W09 | blog still runs 1.3 | • | ns | 2 |
| W10 | api won't stay at 2 replicas at night | •• | ns | 2 |
| W11 | checkout is broken and we can't roll back | •• | ns | 2 |
| W12 | Can't drain k8s-w1 for its kernel update | •• | ns | 2 |

### N - Services & DNS (14)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| N01 | Orders frontend: "upstream timeout", backend pods are healthy | • | ns | 1 |
| N02 | weather API: connection refused through the Service | • | ns | 1 |
| N03 | maps Service broken after the port rename | •• | ns | 1 |
| N04 | kiosk NodePort 30480: works on one node, times out on the others | •• | ns | 1 |
| N05 | storefront can't reach the inventory API since the namespace split | • | ns | 1 |
| N06 | DNS down everywhere after the "local resolver" change | •• | cluster | 1 |
| N07 | external DNS broken in all pods | •• | cluster | 1 |
| N08 | image-scanner floods CoreDNS with NXDOMAIN | ••• | ns | 3 |
| N09 | ring: every member thinks it's alone | •• | ns | 1 |
| N10 | orders lost its database after the migration | •• | ns | 2 |
| N11 | pricing's new Service times out from k8s-w2 | ••• | cluster | 3 |
| N12 | Cross-node pod traffic to and from k8s-w3 is dead | ••• | node | 3 |
| N13 | frontend can't reach vendor search through our alias | ••• | ns | 3 |
| N14 | ledger-ui: fine via port-forward, dead via the Service | •• | ns | 1 |

### G - Ingress & Gateway API (8)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| G01 | gallery.lab: 404 page not found | • | ns | 2 |
| G02 | catalog.lab is unreachable after the move to the new Service | • | ns | 2 |
| G03 | /api/items gives the app's 404 | •• | ns | 2 |
| G04 | secure.lab shows a certificate warning | •• | ns | 2 |
| G05 | The team gateway doesn't route shop.team.lab | •• | ns | 2 |
| G06 | frontdoor.lab: 500, route says RefNotPermitted | •• | ns | 2 |
| G07 | www.store.lab gives 404 | • | ns | 2 |
| G08 | Uploads above 1 MB fail with 413 | •• | ns | 2 |

### X - NetworkPolicy & CNI (10)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| X01 | client can't reach backend since the network policies went live | • | ns | 2 |
| X02 | backend unreachable since "backend-allow" was applied | • | ns | 2 |
| X03 | Prometheus can't scrape appx | •• | ns | 2 |
| X04 | web unreachable although the policy allows its port | •• | ns | 2 |
| X05 | Security audit: every monitoring pod can reach the orders database | ••• | ns | 3 |
| X06 | payx can't reach the payment provider | •• | ns | 2 |
| X07 | Pod networking to and from k8s-w3 died after "simplifying" Calico | ••• | cluster | 3 |
| X08 | Half of the batch workers never start | ••• | ns | 3 |
| X09 | shop down since the "zero trust" change | •• | ns | 1 |
| X10 | Argo CD can't reach Git since the egress hardening | •• | ns | 2 |

### V - Storage (10)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| V01 | uploads: volume never provisioned | • | ns | 1 |
| V02 | wiki can't get a volume since the storage "cleanup" | •• | ns | 1 |
| V03 | archive data volume won't bind to the new claim | •• | ns | 1 |
| V04 | thumbs: only one of two replicas runs | •• | ns | 1 |
| V05 | uploads crash-loops on its new NFS volume | •• | ns | 2 |
| V06 | tsdb is running out of disk and we can't give it more | ••• | ns | 3 |
| V07 | archive's volume is full and won't grow | •• | ns | 2 |
| V08 | old forms volume won't go away | • | ns | 1 |
| V09 | spool-agent never starts on fresh nodes | • | ns | 1 |
| V10 | notes: everything we save disappears after a redeploy | • | ns | 1 |

### A - Security (13)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| A01 | scraper: "pods is forbidden" | • | ns | 1 |
| A02 | anna can't exec into her pods | •• | ns | 1 |
| A03 | janitor can't talk to the API any more | •• | ns | 1 |
| A04 | reporter deployed, but no pods | •• | ns | 2 |
| A05 | payments-ui blocked by "runAsNonRoot" | • | ns | 1 |
| A06 | invoices crashloops after the hardening | • | ns | 1 |
| A07 | SEC finding: every authenticated identity can read all Secrets | •• | ns | 2 |
| A08 | alice can't use her kubeconfig | •• | ns | 2 |
| A09 | Deployments to orders fail: "failed calling webhook" | ••• | ns | 3 |
| A10 | wallet's new pods crash-loop since the egress guard went live | ••• | ns | 3 |
| A11 | The deploy pipeline gets 401 from the API | •• | ns | 2 |
| A12 | payroll: secret-sync job fails every night | •• | ns | 1 |
| A13 | Security: the payments API key may have leaked | ••• | cluster | 3 |

### K - Control plane & etcd (17)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| K01 | kubectl is dead for everyone - workloads still serve | •• | cluster | 1 |
| K02 | API server down after the security hardening | ••• | cluster | 1 |
| K03 | new pods never start - no events at all | •• | cluster | 1 |
| K04 | new Deployment "web" has no pods, scaling does nothing | •• | cluster | 1 |
| K05 | API server unreachable since the etcd disk migration | ••• | cluster | 3 |
| K06 | Someone ran "kubectl delete ns prod" | ••• | cluster | 3 |
| K07 | "x509: certificate has expired" - the certificates were renewed minutes ago | ••• | cluster | 3 |
| K08 | My kubeconfig broke after I "tidied it up" | • | ns | 2 |
| K09 | API down since audit logging was switched on | •• | cluster | 2 |
| K10 | New pods Pending, and there is no scheduler pod | •• | cluster | 2 |
| K11 | The cluster is read-only | ••• | cluster | 3 |
| K12 | New team members can't get their kubeconfigs | ••• | cluster | 3 |
| K13 | CHG-1300: upgrade to Kubernetes 1.37 - zero downtime for storefront | ••• | cluster | 3 |
| K14 | The API "is down" - except on the control-plane node itself | •• | cluster | 2 |
| K15 | k8s-w3 can't rejoin after its rebuild | •• | cluster | 2 |
| K16 | Encryption at rest rollout took the API server down | ••• | cluster | 3 |
| K17 | Desktops get x509 errors from the API, the nodes don't care | •• | cluster | 2 |

### L - Nodes & runtime (18)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| L01 | k8s-w2 is NotReady since last night's maintenance | • | node | 1 |
| L02 | k8s-w1 NotReady after the image-pull tuning | •• | node | 1 |
| L03 | k8s-w2 NotReady after the eviction tuning | •• | node | 1 |
| L04 | k8s-w3 NotReady after the disk cleanup | •• | node | 1 |
| L05 | k8s-w1 NotReady since the API endpoint change | •• | node | 1 |
| L06 | logs and exec broken for everything on k8s-w2 | ••• | node | 1 |
| L07 | Nothing new starts on k8s-w2 | ••• | node | 3 |
| L08 | k8s-w1 keeps going NotReady for a minute, then comes back | ••• | node | 3 |
| L09 | edge-cache pods stuck in ImagePullBackOff on k8s-w1 only | •• | node | 2 |
| L10 | Unknown "netdebug" pod in default - delete doesn't stick | • | node | 2 |
| L11 | inventory DB down: db-0 stuck Terminating since k8s-w3 died | ••• | node | 1 |
| L12 | checkout degraded for an hour after k8s-w2 failed | •• | node | 1 |
| L13 | k8s-w1 sluggish since the "noisy neighbour" fix | ••• | node | 1 |
| L14 | k8s-w2 doesn't come back after the patch reboot | •• | node | 1 |
| L15 | k8s-w3 fails the node baseline audit after its kernel update | • | node | 2 |
| L16 | k8s-w1 NotReady after "maintenance" | •• | node | 2 |
| L17 | k8s-w2 evicts pods for disk space - and the disk looks empty | ••• | node | 3 |
| L18 | Pods on k8s-w3 time out on new connections under load | ••• | node | 3 |

### O - Cluster operations (11)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| O01 | old-team won't go away | •• | ns | 2 |
| O02 | kubectl delete database orders-db hangs | •• | ns | 2 |
| O03 | The old manifests don't apply on the new cluster | • | ns | 2 |
| O04 | Can't upgrade the web release | •• | ns | 2 |
| O05 | helm install web fails on an existing Service | •• | ns | 2 |
| O06 | The retired app still runs | • | ns | 2 |
| O07 | CHG: patch k8s-w2 - drain refuses | •• | ns | 2 |
| O08 | web in kust-prod runs with dev settings | •• | ns | 2 |
| O09 | checkout's feature flags vanished | ••• | cluster | 3 |
| O10 | Our deploy pipeline is blocked by a field-manager conflict | ••• | ns | 3 |
| O11 | widget-reporter is down since the widgets CRD went to v2 | ••• | ns | 3 |

### Q - Observability & forensics (5)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| Q01 | invoicer's logs are empty | • | ns | 2 |
| Q02 | Post-mortem: what restarted the reporting pod? | • | ns | 2 |
| Q03 | k8s-w1 is busy - who is it? | • | ns | 2 |
| Q04 | What happened to api overnight? | •• | ns | 2 |
| Q05 | Some requests to edge fail - which ones? | •• | ns | 2 |

### D - Delivery: Helm & Argo CD (12)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| D01 | demo release "1.4 + Bonjour" never arrived | •• | ns | 1 |
| D02 | demo has been OutOfSync in Argo CD since yesterday | •• | ns | 1 |
| D03 | demo.lab down since the 2.0 release candidate | •• | ns | 1 |
| D04 | payments never deployed - Argo CD refuses | •• | ns | 1 |
| D05 | Argo CD lost the Git repo after the password rotation | • | ns | 2 |
| D06 | demo keeps flipping OutOfSync, pods come and go | •• | ns | 2 |
| D07 | Nothing deploys since the labapp chart refactor | •• | ns | 2 |
| D08 | ledger 1.5 crash-loops, and the rollback didn't stick | •• | ns | 2 |
| D09 | billing's first sync never finishes | •• | ns | 2 |
| D10 | web-prod has 1 pod and logs every health check | •• | ns | 2 |
| D11 | Where is the metrics app? | •• | ns | 2 |
| D12 | notes lost all its data after a "cleanup" commit | ••• | ns | 3 |

### Y - Secrets (10)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| Y01 | demo: the rotated API token is rejected (401) | •• | ns | 1 |
| Y02 | demo is down: "no key could decrypt secret" | ••• | cluster | 3 |
| Y03 | shop down: api and frontend pods can't start | •• | ns | 1 |
| Y04 | prod's API can't start: its secret never arrives | •• | ns | 2 |
| Y05 | Every ExternalSecret stopped refreshing after the CA bundle cleanup | •• | ns | 2 |
| Y06 | Secrets stopped syncing after last night's gw maintenance | • | ns | 2 |
| Y07 | notifier gets 401 from upstream since the token rotation | •• | ns | 2 |
| Y08 | The partner API key keeps changing back to the revoked one | ••• | ns | 3 |
| Y09 | alice can't decrypt the prod secrets | •• | ns | 2 |
| Y10 | Secret scanner: plaintext password in secrets/new-service.enc.yaml | •• | ns | 2 |

### B - Boss fights (several faults at once) (7)

| ID | Ticket | Lvl | Reset | Wave |
|---|---|---|---|---|
| B01 | BLACK FRIDAY: storefront returns errors, 2 hours to the campaign | ••• | ns | 3 |
| B02 | Nothing gets scheduled, nothing gets replaced, one node is gone | ••• | cluster | 3 |
| B03 | New team payments can't deploy anything | ••• | ns | 3 |
| B04 | orders' new in-cluster Postgres: nothing works | ••• | ns | 3 |
| B05 | web is fine in staging, broken in prod | ••• | ns | 3 |
| B06 | DR: x509 errors everywhere, and prod was deleted during the panic | ••• | cluster | 3 |
| B07 | DR drill gone wrong: Argo CD, Sealed Secrets and OpenBao all broken | ••• | cluster | 3 |
<!-- TABLES:END -->

## Rules of the game

* Don't read `learn/*/.lab/` and `scenarios/*/.lab/` - that's the answer key.
* Fix it the way the next on-call would want it: in the manifest, the chart values or Git, so the **next** rollout
  is right. Deleting the guard rail (the PDB, the NetworkPolicy, the webhook, TLS verification) is not a fix - the
  verify scripts check for that.
* A hand-fix on a node is part of some recoveries (etcd, certificates, the kubelet), never the whole story.

## Safety

* `./lab` never talks to the hypervisor: VMs are created, snapshotted and restored only by `k8slab.bat` on the host.
* Everything runs inside the five lab VMs on the host-only network; nothing reaches your LAN. Credentials, the
  kubeconfig, the CA and the golden live in `.state/` (git-ignored) - your `~/.kube` and `~/.ssh` are not touched.
* Every lab object is labelled `lab.k8slab/scenario=<ID>`; the cleanup works from the cheapest reset that undoes
  everything: delete the lab's objects (`ns`), restore a node's files and runtime state (`node`), or put back the
  golden etcd snapshot, node files and gw data (`cluster`, 1-3 min). If something is left, the next start notices
  and escalates to a full cluster reset.
* The panic button stays `k8slab.bat restore baseline`. After **any** VM snapshot restore run `./lab cluster
  doctor`: the registry's images are not in the golden (`./lab images build <tag>` puts a missing labapp tag back).

## Maintenance

```bash
./lab cluster doctor             # 33 checks: nodes, add-ons, DNS, storage, ingress, GitOps & secrets, registry
./lab cluster reset              # back to the golden baseline (~1 min)
./lab selftest <ID..>            # start -> verify must FAIL -> solve -> verify must PASS
./lab selftest wave1|wave2|wave3|learn|all     # ~78 min | ~105 min | ~2 h | ~30 min | ~6 h
python3 tools/tables.py --readme # regenerate the tables above after adding a lab
tests/modes-selftest.sh          # interview / exam / chaos self-run (~5 min)
```
Upgrading: edit `versions.env`, rebuild (`./lab cluster rebuild`, `./lab cluster golden`), `./lab selftest all`.
The learn lab T09 and the incident K13 rebuild the cluster at the previous minor in their setup and upgrade it;
everything else expects the golden baseline.
