# How the faults are made (and how to build your own)

Every lab is a real failure on the real cluster: 5 VirtualBox VMs (`k8s-gw`, `k8s-cp1`, `k8s-w1..3`),
kubeadm v1.37, Calico, MetalLB, Traefik, Argo CD, Sealed Secrets, ESO + OpenBao. A scenario's `setup.sh`
breaks something the way it breaks in production. `verify.sh` checks the **outcome** (what users and
operators observe), never the keystrokes. `solve.sh` is the reference fix that `./lab selftest` uses.

## Anatomy

```
scenarios/<ID>-kebab/            (learn/T..-kebab/ for the learn track: same files, kind: learn)
  scenario.yaml   id, title, kind, level (1-3), domain, wave, est, reset, namespaces, nodes, gitops, [openbao, pilot,
                  timed: false = not picked by interview / exam / chaos, e.g. a long rebuild]
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

Tickets refer to `workspace/<ID>/...`: when a lab is hidden (`./lab start random`, interview, exam, chaos) the
ticket shows `workspace/current/...`, a symlink to the same directory, and no command prints the ID.

## Reset levels - pick the cheapest one that undoes *everything* setup and the student may change

| `reset:` | Undoes | Use for |
|---|---|---|
| `ns` | the `namespaces:` + every object labelled `lab.k8slab/scenario=<ID>` (anywhere) | workloads, Services, config, RBAC, policies - confined to the scenario's own namespaces / labelled objects |
| `node` | `ns` + the golden node files, runtime faults and pods on `nodes:` | kubelet, containerd, CNI config, sysctls, swap, modules, clock, nft/tc on a worker |
| `gw` | `ns` + gw's haproxy, chrony, NFS, nginx, registry, Gitea and OpenBao data | API load balancer, registry, Git server, secret store faults |
| `cluster` | everything: etcd snapshot restore + every node + gw (~60 s) | control plane, etcd, anything touching shared objects (kube-system ConfigMaps/DaemonSets, CoreDNS, kube-proxy, Calico, CRDs, Argo CD itself) |

Add **`gitops: true`** when the scenario commits to `lab/gitops`. The cleanup then force-pushes the tag
`baseline` to `main`, and Argo CD re-syncs and waits until `lab-apps`, `demo` and `shop` are Synced and
Healthy. It also puts back Argo CD's repo Secret `argocd/repo-gitops` (Gitea user `argocd`, read-only; D05
rotates its password) and the spec of the hand-bootstrapped root app `lab-apps` (D11). The student also gets
`workspace/gitops`. Applications and AppProjects outside the baseline are deleted, apps first. An app whose AppProject is already gone has its finalizer stripped: Argo CD can't
finalize it, and it would keep `lab-apps` unhealthy (D04). Its resources must sit in the scenario's
`namespaces:`, which the cleanup deletes next.

Add **`openbao: true`** when setup or the student may change OpenBao (kv paths, policies, auth roles). The
cleanup then restores the raft snapshot that `./lab cluster golden` saved (`.state/golden/openbao.snap`), in
about 7 s, with the same root token. ESO picks the store up again by itself. This is much cheaper than `gw`.
If OpenBao is sealed or down (Y06 breaks its seal key), `/etc/openbao` comes back from the gw golden and
OpenBao restarts first.

Every cleanup also **normalizes the Node objects**:
- it uncordons every node;
- it puts back the `topology.kubernetes.io/zone` labels;
- it removes the taints a scenario may add, keeping the control-plane taint and the kubelet's own
  `node.kubernetes.io/*` taints, but removing `out-of-service`.

Any other Node labels a scenario adds (e.g. `disktype`) go in its `cleanup.sh`.

A `node` reset also re-enables chrony and waits (up to 30 s) for the clock to sync (L16 disables it and
moves the clock 400 days back). It deletes `Failed` pods in every namespace: evictions (R04, R08) leave
them behind, and `cluster_quick` would count them as broken system pods.

**Rule of thumb**: if setup or a plausible wrong fix can change an object you didn't create, use `cluster`.
After every cleanup, `cluster_quick` checks nodes, system pods and Argo apps. If that fails, the next `start`
escalates to a full `cluster reset` by itself.

## Techniques and helpers

| Helper | What |
|---|---|
| `kns ns..` / `ka -f file|-` | create namespaces / apply objects - always labelled for cleanup. `kns` first waits (up to 4 min) for a namespace of the previous run that is still Terminating |
| `kx ...` | kubectl against the lab cluster |
| `nx <node> '<cmd>'` / `nxi <node>` | root on a node (command / script on stdin) |
| `wait_rollout ns kind/name [s]` | rollout status with a timeout |
| `http_code ns url [header]` / `http_ok ...` | HTTP status seen **from inside** the cluster (throwaway busybox pod) |
| `http_out url [Host]` | HTTP status **from the desktop** (MetalLB 192.168.56.200, NodePorts) |
| `tcp_ok_as ns labels\|- host:port` / `check_reach <<'EOF'` | TCP connect from a throwaway agnhost pod that carries `labels` (the NetworkPolicy view); `check_reach` = one check per row `ns labels host:port open\|blocked`, probes in parallel. Don't give a probe labels that a ReplicaSet selects - it would adopt it |
| `answer key` / `answered key truth [alt..]` | exploration labs: the student's `workspace/<ID>/answers.yaml` vs. the live value (trimmed, case-insensitive) |
| `cluster_bare_build <version>` | a bare cluster (control plane + workers + Calico) at an older version, cp1's PKI kept (CA + SA key: the desktop kubeconfig stays valid) - for upgrade labs; needs `reset: cluster` |
| `restarts ns selector` / `stable_for s ns selector` | restart counters / "Ready, no restart in the last s seconds (`lastState.terminated.finishedAt`) and none while watching s seconds" (Failed/Succeeded pods, e.g. evicted ones, are ignored) |
| `crashlooping ns selector` | a container waits in CrashLoopBackOff **or** has restarted at least twice after a non-zero exit - for setups that wait for a crash loop |
| `deploy_ready ns name [n]` / `has_endpoints ns svc` | ready = updated = total replicas (n, default spec.replicas) / the Service has a ready EndpointSlice address |
| `can_i <user|system:serviceaccount:ns:sa> verb resource [-n ns]` | RBAC from the subject's point of view. Subresources: `can_i anna create pods --subresource=exec` - `pods/exec` would mean a pod *named* exec |
| `fault_partition node` / `fault_clear node` | cut a node off the cluster network (nft table `lab_fault`), keep the desktop's SSH |
| `gitops_commit "msg" <<'EOF' ... EOF` | change lab/gitops as a colleague (`dev-bob`), pushed to `main` |
| `argo_refresh app` / `argo_sync app` / `argo_app_ok app` | Argo CD |
| `gx /api/path` / `bx <bao args>` | Gitea API (user lab) / OpenBao CLI (root) |
| `check desc cmd..` / `check_eventually s desc cmd..` / `verdict` | verify building blocks |
| `remember k v` / `recall k` | facts from setup to verify (kept in `.state`) |
| `pods_get ns selector path [port]` | what every Running pod answers on `localhost:<port><path>` (`labapp get` inside the pod), one body per line - per-replica config checks |
| `https_out host [path]` | HTTPS status from the desktop through the LB (443), the cert verified against the lab CA for `host`; `000` = TLS failed (Traefik's default cert, wrong name) |
| `load_test ns url [-c N -d S --rps N]` | `labapp load` from a throwaway pod: JSON `{requests, errors, codes, rps, p50_ms, p90_ms, p99_ms}` (`{}` if the pod failed). Runs without the 10 s API timeout of verify |
| `node_reboot node [s]` | reboot from inside the guest, wait for a new boot id over SSH. Not for Ready: the caller decides what "back" means |
| `ns_matrix ns selector [port]` | every Running labapp pod reaches every other one by pod IP (`labapp get /health`); failing pairs on stderr as `node -> node (ip)` (N12, X07) |
| `outage_probe start name url [host]` / `gaps name` / `stop name` | a prober on gw, a request every 0.5 s for at most 1 h; `gaps` = the failed probes. gw is never drained, so it watches a rollout or an upgrade from outside (P16, K13). Stop it in `cleanup.sh` |
| `coredns_count [rcode]` | DNS requests (or `NXDOMAIN` etc. responses) summed over the CoreDNS pods' `:9153` metrics; compare before/after (N08) |
| `user_kubeconfig user group[,group] file` | a client cert from the cluster CA through the CSR API (CSR `lab-<user>`, labelled) + a kubeconfig that uses it |
| `registry_ci_password` / `private_registry_ok` | the private registry `registry.lab:5001` (same images, read-only, user `ci`): its password / "401 anonymous, ci can read" |
| `gitea_argocd_user` / `argo_repo_secret` | Argo CD's Gitea account (password back to `.state/gitea/argocd-password`) / its repo Secret |
| `eso_store_restore` | the caProvider ConfigMap `external-secrets/lab-ca` + ClusterSecretStore `openbao` as built |

### Gotchas

#### Scripting and the lab framework

- **`check_eventually 60 "x" test "$(cmd)" = y` evaluates `$(cmd)` once.** Wrap it in a function.
- **In selftest's "broken" pass, `LAB_EXPECT_FAIL=1` shortens `check_eventually` to 3 s.** Setup must wait
  until the broken state really exists (e.g. node NotReady, app OutOfSync) before it returns.
- **Selftest output belongs in `.state/`, not `/tmp`.** The desktop's `/tmp` is wiped at boot.
  `./lab selftest` appends every result line to `.state/selftest.log`. It keeps a failed setup's log as
  `.state/selftest-setup-<ID>.log`. A `set -e` setup/solve prints `✘ line N: exit X: <command>` when a command
  other than `die` stops it.
- **No `yq` in lab scripts.** The desktop's `yq` is a snap that doesn't run here. Use python3 + PyYAML (as `ka`
  does) or jq on `-o json`.
- **Setups run with `pipefail`**: `kx ... | grep -q X` fails whenever kx fails, even when grep matched (K17 waited
  for an x509 error that `kx` reports by failing). Capture first: `o=$(kx ... 2>&1) || true; grep -q X <<<"$o"`.
- **jq 1.6 (the desktop's) exits 0 for `-e` on empty input** (jq 1.7 exits 4). `pods_get ... | jq -e '.x'` is "true"
  when every request timed out and nothing was printed (X01's setup never saw the fault). For output that may be
  empty, slurp and count: `jq -se 'length > 0 and all(.[]; ...)'`.
- **busybox >= 1.29 `nslookup <short name>` exits 1** when any search domain answers NXDOMAIN, even though
  the name resolves. Use FQDNs or dotted names in checks, and `labapp wait-for` in init containers (P12).
  busybox 1.37 `wget` does https.
- **busybox `wget -S` adds a last line on errors**: `wget: server returned error: HTTP/1.1 502 ...`. `http_code`
  reads only the status header line (`^ *HTTP/`); before Phase 6 it returned 0 for every 4xx/5xx.
- **The API server pretty-prints JSON for curl/wget user agents**: match `"kind": *"PodList"`, not
  `"kind":"PodList"` (A03).
- **`kubectl run --rm -i` can attach late**: a probe pod that finishes fast loses its first lines. Let it `sleep 2`
  before it prints, and don't require an exact count of lines (W03).
- **Check state, don't trigger it**: a setup that tests "undo is impossible" by running `rollout undo` repairs the
  lab if the check runs too early. Use `--dry-run=server` (W11), and wait for the exact state (the 1.5 ReplicaSet,
  not "one ReplicaSet").
- **Probe pods and ReplicaSets**: a policy probe must not carry the labels a ReplicaSet selects (it would be
  adopted). Select with a label the RS doesn't use (X10 uses `app.kubernetes.io/component`), or give the
  workload an extra selector label (X02's `tier: x02`).
- **`pkill -f` matches its own shell** when the pattern appears in the command line: use pid files (`outage_probe`).
- **Count live pods, not `phase=Running`**: during a rollout the old pods are still Running while terminating.
  Filter `metadata.deletionTimestamp == null` (S05, A10).
- **"Ready" is not "stable".** A pod killed every ~40 s by a bad liveness probe is Ready between kills, and
  a crash-looping container is `running` or `terminated` most of the time. Poll `crashlooping`, not
  the waiting reason, and check stability with `stable_for` (which looks back), not with readiness (P04, P09).
- **`cleanup.sh` is for shared state the reset level doesn't own**: Node labels (S02), the default
  StorageClass annotation (V02), NetworkPolicies in namespaces the scenario doesn't own (X09), static PVs
  and their NFS directories (V03), a Role in `default` (A01).
- **Cluster-scoped objects the student re-applies lose the lab label**: a PriorityClass, a CRD, an IPPool or a
  StorageClass applied from a workspace file without the label survives the label sweep. Delete them by name in
  `cleanup.sh` (S10, O11, X08, D12) - remember `cleanup.sh` is skipped at reset level `cluster`.
- **Check error texts against the running version.** Argo CD 3.5 reports a denied destination as "do not
  match any of the allowed destinations"; "not permitted" is the repo/resource-kind check (D04). `grep -a`
  the binary for the string when in doubt.
- **Audit logs survive every reset**: `/var/log/kubernetes/audit` is not in the golden. A lab that reads the
  audit log clears it first (`audit_enable` does; K09's setup too) - A13/O09 leave theirs behind.

#### Kubernetes behaviour the scenarios rely on

- **Changing a scheduling constraint can deadlock the rollout.** Required pod anti-affinity is symmetric: the
  old pods repel the new ones, and the old ReplicaSet can't shrink below `replicas - maxUnavailable`. The
  solve must remove the old ReplicaSet (S04). A `DoNotSchedule` topology spread counts the tainted
  control plane as an empty domain unless `nodeTaintsPolicy: Honor`.
- **Rolling updates and topology spread**: without `matchLabelKeys: [pod-template-hash]` the new ReplicaSet spreads
  around the old pods and can end up uneven (S05).
- **A Deployment deletes old ReplicaSets only when a rollout completes.** With a crashing new version the old
  ReplicaSet stays, whatever `revisionHistoryLimit` says, and `rollout undo` still works. A "no history" lab
  needs a release that rolls out completely and breaks at runtime (W11).
- **`maxUnavailable: 25%` of 1 replica rounds down to 0**: a broken new pod never replaces the old one, and the
  old one keeps serving. A fault in a single-replica add-on needs `strategy: Recreate` (R02).
- **`memory.available` drifts by hundreds of MiB** (page cache moving between active and inactive, a kubelet
  restart). An eviction threshold "free + 300Mi", measured once, sometimes evicted nothing, and a bigger margin
  would outlast the victim's ~600 MiB and evict other pods. Measure, set, wait for the eviction, and re-measure
  if none came (R04).
- **Server-side apply after `--force-conflicts`**: the old manager loses the value but may keep co-owning a list
  item's key (`f:name`) - check `f:value`, not the whole `f:env` (O10).
- **Helm 4 applies server-side**: after a hand patch (`kubectl patch` = field manager `kubectl-patch`), a plain
  `helm upgrade` fails with a conflict and leaves the release `failed`. `helm_up` passes `--force-conflicts`, so
  re-applying an add-on from its golden values always wins (R02's cleanup).
- **Don't assume a fault without checking what the node falls back to.** Without `--node-ip` the kubelet
  resolves its hostname first (`/etc/hosts` maps it to the host-only IP). Only a loopback answer makes it use
  the default-route NIC (L06). Read the kubelet's fallback order before emulating a "lost flag".

#### Networking and storage on these VMs

- **Egress device rules go in POSTROUTING.** In the nftables OUTPUT hook, `oifname` is the device chosen
  *before* kube-proxy's DNAT re-routes a packet. Host → 10.96.0.1 first routes via the NAT NIC, so an
  output-hook "drop enp0s3" kills the node's own API calls and Calico CNI fails.
- **The desktop reaches the VMs through VirtualBox NAT.** Nodes see it as **192.168.56.1**; a partition
  fault must keep that address, or `./lab` loses the node.
- **Calico autodetection on these VMs**: `first-found` picks the host-only NIC; `can-reach=<internet IP>` follows the
  default route to the NAT NIC (`10.0.2.15`, the same on every VM) (X07). IPPools are CRD-only
  (`crd.projectcalico.org/v1`, no defaulting); exhaustion says *No IPs available in pools* (X08).
- **Traefik vs ingress-nginx error codes**: a wrong backend Service port → Traefik skips the route (404 + "service
  port not found" in its log); no ready endpoints → 503 (`allowEmptyServices`). Traefik serves several Gateways
  on one entrypoint (G05 has its own Gateway on `web:8000`).
- **Open connections hide faults**: a haproxy `reload` keeps established connections on the old process, and
  TLS validity is checked only at the handshake. The kubelets' long-lived connections kept working after a bad
  LB backend (K14) or a clock 400 days back (L16) until something restarted them.
- **NFS checks groups on the server** (`rpc.mountd --manage-gids` on Ubuntu): `fsGroup` is only a supplementary
  group, so a pod writes to an NFS volume only if `runAsGroup` (the primary group) matches the directory's group
  (V05, V07).
- **A VM snapshot restore rolls the registry back**: its storage is not in the golden, so a labapp tag pushed
  after the snapshot is gone (A09/A10 failed without a word). `./lab cluster doctor` checks every `LABAPP_TAGS`
  tag; `./lab images build <tag>` puts one back.

#### GitOps and secrets

- **An Argo CD sync only reverts what Git declares.** A field added by hand that Git never had (an extra env
  var, label or annotation) survives a sync and self-heal, and the app still says Synced. If a GitOps
  scenario's setup adds one, its solve and hints must remove it explicitly (D02).
- **GitOps reset races**: `lab-apps`' prune can fail on an Application the reset is deleting ("... not found"),
  and auto-sync never retries a failed revision. The reset re-syncs the root until it converges
  (`root_converged`). Without that the next start saw an unhealthy cluster and did a full reset (D08).
- **Hooks and their dependencies**: Argo CD runs PreSync hooks before any Sync-phase object exists, and that
  includes the chart's own ServiceAccount (D09: the Job couldn't even create its pod). Hook resources carry
  `argocd.argoproj.io/hook-finalizer`: when the app is deleted, strip it, or the namespace hangs in Terminating.
- **A failed automated sync is never retried for the same revision**: an app that tried to sync while its repo
  was unreachable stays failed after the credentials are back - sync it explicitly (B07, and `root_converged` in
  the reset).

#### Control plane, etcd and recovery

- **Never leave files under `/etc/kubernetes/manifests`** except the 4 control-plane manifests: kubelet
  runs every file there.
- **etcd NOSPACE**: after raising the quota, wait for the **new** etcd process before `alarm disarm` - the old one
  re-raises the alarm at once, and the alarm is persisted across the restart. `etcdctl endpoint health` reports
  *unhealthy* while any alarm is active - wait with `endpoint status` (K11). haproxy drops the API server for a few
  seconds while etcd restarts (EOF through the LB).
- **After an etcd restore, restart every kubelet**: their watches point at revisions newer than the restored
  store and stall - new pods on their nodes stay Pending (B06). The same for calico-node (new pods get no network)
  and kube-proxy: `rollout restart` both DaemonSets.
- **Pods restored from an etcd snapshot are ghosts**: the Pod objects come back *Running* and Ready, but their
  kubelets terminated those UIDs and never restart them (`exec`: *pod does not exist*; a kubelet restart revives the
  container, not its network). Force-delete them (`--grace-period=0 --force`: a graceful delete hangs in Terminating, no kubelet confirms it); verify with `pods_get` /
  `exec`, never with `deploy_ready` alone (K06, B06).

Lab images beyond labapp (`LAB_IMAGES` in `versions.env`, mirrored by gw's `sync.sh`; `<path>=<ref>[%platform]`):
`lab/redis:7-alpine`, `lab/postgres:16-alpine`, `lab/nginx:1.30-alpine`, and `lab/labapp:1.6`, an **arm64**
python image under an ordinary tag (P03: `exec format error`). `registry.lab:5001` serves the same images
behind htpasswd (P02: pulls need an imagePullSecret); every node has a `certs.d` entry for it.

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
