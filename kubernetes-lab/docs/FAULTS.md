# How the faults are made (and how to build your own)

Every lab is a real failure on the real cluster: 5 VirtualBox VMs (`k8s-gw`, `k8s-cp1`, `k8s-w1..3`),
kubeadm v1.37, Calico, MetalLB, Traefik, Argo CD, Sealed Secrets, ESO + OpenBao. A scenario's `setup.sh`
breaks something the way it breaks in production. `verify.sh` checks the **outcome** (what users and
operators observe), never the keystrokes. `solve.sh` is the reference fix that `./lab selftest` uses.

## Anatomy

```
scenarios/<ID>-kebab/            (learn/T..-kebab/ for the learn track: same files, kind: learn)
  scenario.yaml   id, title, kind, level (1-3), domain, wave, est, reset, namespaces, nodes, gitops, [openbao, pilot]
  ticket.md       "# Title", the incident as the reporter sees it, and a **Test**: line (what verify checks)
  hints.md        3 x "## Hint n": where to look -> what's wrong -> how to fix
  manifests/      optional: copied to workspace/<ID>/ ("as found", ./lab diff shows the student's changes)
  .lab/setup.sh   build the broken state            (bash -euo pipefail)
  .lab/verify.sh  check ... ; verdict              (bash -u, NO pipefail: `kubectl | grep -q` races)
  .lab/solve.sh   the reference fix                (bash -euo pipefail)
  .lab/solution.md  root cause, diagnosis commands, fix, interview notes
  .lab/cleanup.sh   optional: leftovers the reset level doesn't cover (cluster-scoped CSRs, Retain PVs)
  .lab/facts.sh     optional: the live truth an answers.yaml is checked against (sourced by verify + solve)
```

The scripts run on the desktop VM, from `workspace/<ID>/`, with `lib/{common,vm,cluster,gitops,golden,scenario}.sh`
loaded. `$SCN` is the scenario directory and `$LAB_ID` its ID. During `verify`, every API request has a 10 s
timeout (`KX_TIMEOUT`), so a dead API fails a check instead of hanging it.

## Reset levels - pick the cheapest one that undoes *everything* setup and the student may change

| `reset:` | Undoes | Use for |
|---|---|---|
| `ns` | the `namespaces:` + every object labelled `lab.k8slab/scenario=<ID>` (anywhere) | workloads, Services, config, RBAC, policies - confined to the scenario's own namespaces / labelled objects |
| `node` | `ns` + the golden node files, runtime faults and pods on `nodes:` | kubelet, containerd, CNI config, sysctls, swap, modules, clock, nft/tc on a worker |
| `gw` | `ns` + gw's haproxy, chrony, NFS, nginx, registry, Gitea and OpenBao data | API load balancer, registry, Git server, secret store faults |
| `cluster` | everything: etcd snapshot restore + every node + gw (~60 s) | control plane, etcd, anything touching shared objects (kube-system ConfigMaps/DaemonSets, CoreDNS, kube-proxy, Calico, CRDs, Argo CD itself) |

Add **`gitops: true`** when the scenario commits to `lab/gitops`. The cleanup then force-pushes the tag
`baseline` to `main`, and Argo CD re-syncs and waits until `lab-apps`, `demo` and `shop` are Synced and
Healthy. The student also gets `workspace/gitops`.

Add **`openbao: true`** when setup or the student may change OpenBao (kv paths, policies, auth roles). The
cleanup then restores the raft snapshot that `./lab cluster golden` saved (`.state/golden/openbao.snap`), in
about 7 s, with the same root token. ESO picks the store up again by itself. This is much cheaper than `gw`.

Every cleanup also **normalizes the Node objects**:
- it uncordons every node;
- it puts back the `topology.kubernetes.io/zone` labels;
- it removes the taints a scenario may add, keeping the control-plane taint and the kubelet's own
  `node.kubernetes.io/*` taints, but removing `out-of-service`.

Any other Node labels a scenario adds (e.g. `disktype`) go in its `cleanup.sh`.

**Rule of thumb**: if setup or a plausible wrong fix can change an object you didn't create, use `cluster`.
After every cleanup, `cluster_quick` checks nodes, system pods and Argo apps. If that fails, the next `start`
escalates to a full `cluster reset` by itself.

## Techniques and helpers

| Helper | What |
|---|---|
| `kns ns..` / `ka -f file|-` | create namespaces / apply objects - always labelled for cleanup |
| `kx ...` | kubectl against the lab cluster |
| `nx <node> '<cmd>'` / `nxi <node>` | root on a node (command / script on stdin) |
| `wait_rollout ns kind/name [s]` | rollout status with a timeout |
| `http_code ns url [header]` / `http_ok ...` | HTTP status seen **from inside** the cluster (throwaway busybox pod) |
| `http_out url [Host]` | HTTP status **from the desktop** (MetalLB 192.168.56.200, NodePorts) |
| `tcp_ok_as ns labels\|- host:port` / `check_reach <<'EOF'` | TCP connect from a throwaway agnhost pod that carries `labels` (the NetworkPolicy view); `check_reach` = one check per row `ns labels host:port open\|blocked`, probes in parallel. Don't give a probe labels that a ReplicaSet selects - it would adopt it |
| `answer key` / `answered key truth [alt..]` | exploration labs: the student's `workspace/<ID>/answers.yaml` vs. the live value (trimmed, case-insensitive) |
| `cluster_bare_build <version>` | a bare cluster (control plane + workers + Calico) at an older version, cp1's PKI kept (CA + SA key: the desktop kubeconfig stays valid) - for upgrade labs; needs `reset: cluster` |
| `restarts ns selector` / `stable_for s ns selector` | restart counters / "Ready and no restarts for s seconds" |
| `deploy_ready ns name [n]` / `has_endpoints ns svc` | ready = updated = total replicas (n, default spec.replicas) / the Service has a ready EndpointSlice address |
| `can_i <user|system:serviceaccount:ns:sa> verb resource [-n ns]` | RBAC from the subject's point of view |
| `fault_partition node` / `fault_clear node` | cut a node off the cluster network (nft table `lab_fault`), keep the desktop's SSH |
| `gitops_commit "msg" <<'EOF' ... EOF` | change lab/gitops as a colleague (`dev-bob`), pushed to `main` |
| `argo_refresh app` / `argo_sync app` / `argo_app_ok app` | Argo CD |
| `gx /api/path` / `bx <bao args>` | Gitea API (user lab) / OpenBao CLI (root) |
| `check desc cmd..` / `check_eventually s desc cmd..` / `verdict` | verify building blocks |
| `remember k v` / `recall k` | facts from setup to verify (kept in `.state`) |

Gotchas:
- **`check_eventually 60 "x" test "$(cmd)" = y` evaluates `$(cmd)` once.** Wrap it in a function.
- **Egress device rules go in POSTROUTING.** In the nftables OUTPUT hook, `oifname` is the device chosen
  *before* kube-proxy's DNAT re-routes a packet. Host → 10.96.0.1 first routes via the NAT NIC, so an
  output-hook "drop enp0s3" kills the node's own API calls and Calico CNI fails.
- **The desktop reaches the VMs through VirtualBox NAT.** Nodes see it as **192.168.56.1**; a partition
  fault must keep that address, or `./lab` loses the node.
- **In selftest's "broken" pass, `LAB_EXPECT_FAIL=1` shortens `check_eventually` to 3 s.** Setup must wait
  until the broken state really exists (e.g. node NotReady, app OutOfSync) before it returns.
- **Never leave files under `/etc/kubernetes/manifests`** except the 4 control-plane manifests: kubelet
  runs every file there.
- **An Argo CD sync only reverts what Git declares.** A field added by hand that Git never had (an extra env
  var, label or annotation) survives a sync and self-heal, and the app still says Synced. If a GitOps
  scenario's setup adds one, its solve and hints must remove it explicitly (D02).
- **`cleanup.sh` is for shared state the reset level doesn't own**: Node labels (S02), the default
  StorageClass annotation (V02), NetworkPolicies in namespaces the scenario doesn't own (X09), static PVs
  and their NFS directories (V03), a Role in `default` (A01).
- **Selftest output belongs in `.state/`, not `/tmp`.** The desktop's `/tmp` is wiped at boot.
  `./lab selftest` appends every result line to `.state/selftest.log`.

## Build your own scenario

1. Copy a pilot that has the same reset level: `N01` (ns), `L01` (node), `K01` (cluster), `D02` (GitOps).
2. Write the ticket from the reporter's point of view: symptoms, not causes. End it with a **Test** line.
3. `setup.sh` breaks things and waits until the symptom is real. `verify.sh` checks the outcome, including
   the "don't cheat" guards, e.g. "pod labels unchanged" or "the freeze is still in Git".
4. `./lab selftest <ID>` must show `broken:ok fixed:ok`. Run it twice, then once after a different
   scenario.

## Learn labs (`learn/Tnn-*`, `kind: learn`)

Same files and the same selftest (before the student's work verify must FAIL). Guided steps in the ticket,
hints that give the commands, a solution with takeaways. Exploration labs keep the facts in a template
`manifests/answers.yaml` and compute the truth live in `.lab/facts.sh`, so a pod that moved or a
re-built CA never makes a stale answer "right".

## What the lab deliberately does NOT do

- No hypervisor tricks from inside the lab: `./lab` never controls VirtualBox, so every fault is in-guest.
- No hidden state on the nodes: the golden baseline lives on the desktop (`.state/golden`).
- No grading of *how* you fixed it, unless the ticket forbids a shortcut (then a guard check).
