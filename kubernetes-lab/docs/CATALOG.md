# Scenario catalog - 195 incidents + 16 learn labs (SPOILERS)

> Every row reveals the root cause and how it is injected. Fine while reviewing the plan;
> once the lab is built, practise from tickets only (`./lab start <id>`).

Columns: **Lvl** 1 = one obvious layer, 2 = needs the right concept/tool, 3 = multi-layer / internals.
**Reset** (cheapest level that restores the golden baseline):
- `ns` = delete the scenario's labelled objects and Argo CD apps, force-push Gitea `baseline` → `main`, restore the OpenBao kv;
- `node` = push the node's golden files, undo runtime faults (nft `lab_fault`, tc, sysctls, swap, modules, SIGSTOP, clock), restart containerd + kubelet;
- `cluster` = `node` on every VM + etcd snapshot restore + gw data restore + `doctor`;
- `rebuild` = `kubeadm reset` + `cluster build` + golden (~10 min; the upgrade scenario starts at 1.36).

**Emulation** = what `setup.sh` does. **Verify** = what `./lab verify` checks (outcome, not method).

Cluster: `k8s-cp1` (control plane), `k8s-w1` + `k8s-w2` (zone-a), `k8s-w3` (zone-b), `k8s-w4` (spare VM, not
joined), `k8s-gw` (haproxy API LB, registry, Gitea, OpenBao, NFS, dnsmasq, chrony). `./lab` has no hypervisor
access: node faults are injected inside the guest (nft partition table, SIGSTOP kubelet, CPUQuota, tc netem,
reboot, `date -s`, short-lived kubeadm certs).

Shorthand: `kx` = kubectl on the desktop, `nx <node>` = ssh + sudo into a node VM, `gx` = git/API against the
Gitea repo `lab/gitops`, `bx` = bao CLI against OpenBao, "curl-probe" = a short-lived `curl` pod checking a URL
from inside the cluster.

---

## P - Pods & containers (16)

| ID | Ticket (symptom) | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| P01 | New release never starts: `ImagePullBackOff` | 1 | ns | Deployment image tag `labapp:1.4.0` (only `1.4` exists in the registry) | rollout complete, all replicas Ready, image still `labapp` family |
| P02 | Private image can't be pulled, public ones fine | 2 | ns | image on the htpasswd registry (`k8s-gw:5001`); no `imagePullSecrets`; a correct-looking secret exists in **another** namespace | pods Ready; secret lives in the app namespace (no registry auth removed) |
| P03 | Pod crashes instantly, logs say `exec format error` | 2 | ns | `arm64` variant pushed under the amd64 tag | pods Ready on amd64 image (multi-arch or correct tag) |
| P04 | `CrashLoopBackOff` right after deploy, works in dev | 1 | ns | labapp exits 1 when `DATABASE_URL` missing; env var renamed `DB_URL` in manifest | Ready, restartCount stops increasing for 60 s |
| P05 | `CrashLoopBackOff` but logs show "done" and exit code 0 | 2 | ns | Deployment runs a one-shot migration command (exits 0) with `restartPolicy: Always` | migration moved to a Job (Completed) + web Deployment Ready |
| P06 | `CreateContainerConfigError` | 1 | ns | `secretKeyRef` key `password` but Secret has `passwd` | pods Ready, secret value unchanged |
| P07 | `RunContainerError: exec: "gunicorn": executable file not found` | 1 | ns | `command:` overrides entrypoint with a binary not in the image | pods Ready, readiness passes |
| P08 | Pods restart under load, `Last State: OOMKilled` (137) | 1 | ns | labapp cache 192 Mi, limit 128 Mi | stable 60 s under load, `CACHE_MB` unchanged |
| P09 | Healthy app killed every ~30 s | 1 | ns | liveness probe on port 8081 (app listens 8080) | no liveness kills for 60 s, liveness still present |
| P10 | Pods Running but `0/1 Ready`; Service times out | 1 | ns | readiness `/healthz` (app serves `/health`) | Ready; Service endpoints populated; curl-probe 200 |
| P11 | Pods never get past startup on big datasets | 2 | ns | app needs 45 s warm-up; liveness initialDelay 10 s, no startupProbe | Ready, 0 restarts for 90 s, liveness kept (startupProbe added) |
| P12 | Pods stuck in `Init:0/1` | 1 | ns | init container waits for `nslookup postgres` (service is `postgresql`) | Running/Ready, init container still present |
| P13 | `kubectl delete pod` hangs, pod stays `Terminating` | 2 | ns | pod with custom finalizer `example.com/cleanup` + app ignores SIGTERM, grace 600 s | pod gone; Deployment healthy; explain finalizer in solution |
| P14 | Job never reaches Completed although the work is done | 3 | ns | Job with a log-shipper sidecar as a regular container (never exits) | Job Complete (native sidecar `restartPolicy: Always` initContainer) |
| P15 | Pod `Evicted`: "ephemeral local storage usage exceeds the total limit" | 2 | ns | app writes 300 Mi to emptyDir, `ephemeral-storage` limit 100 Mi | stable 60 s; data path is a volume with `sizeLimit`/PVC |
| P16 | Graceful shutdown drops in-flight requests during rollouts | 3 | ns | no `preStop`, app exits before endpoints removed; load test shows 5xx during rollout | rollout under load with 0 errors (preStop sleep / terminationGrace) |

## C - Configuration (8)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| C01 | Changed the ConfigMap, app still uses old value | 1 | ns | value consumed via `env`/`envFrom` | app reports new value (rollout restart / hash annotation) |
| C02 | Mounted config file never updates | 2 | ns | ConfigMap mounted with `subPath` | file content updated in running pods |
| C03 | App says "invalid password", secret looks right | 2 | ns | `data:` contains base64 of an already base64 string | app authenticates to redis |
| C04 | nginx won't start after adding a config file: `mime.types` not found | 2 | ns | ConfigMap mounted over `/etc/nginx` (hides image files) | nginx Ready, custom config active |
| C05 | `CreateContainerConfigError: configmap "app-config" not found` - but it exists | 1 | ns | ConfigMap is in namespace `default`, pod in `shop` | Ready; config in the right namespace |
| C06 | Can't apply config change: "field is immutable" | 2 | ns | `immutable: true` ConfigMap | new values live (new object/generator hash), old one may remain |
| C07 | Auth header rejected only in Kubernetes | 3 | ns | Secret created `--from-file` with trailing newline; app sends `Bearer token\n` | upstream returns 200 |
| C08 | Downward API env empty / pod won't start | 2 | ns | `fieldRef: status.podIp` (case) / `resourceFieldRef` without container | Ready, env shows pod IP and memory limit |

## S - Scheduling (14)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| S01 | New pods `Pending`: "Insufficient cpu" | 1 | ns | `requests.cpu: "16"` | Running, requests realistic (< 1 CPU) |
| S02 | `Pending`: "didn't match Pod's node affinity/selector" | 1 | ns | `nodeSelector: disktype: ssd`, nodes labelled `disk=ssd` | Running on the ssd node |
| S03 | `Pending`: "untolerated taint" | 1 | ns | all workers tainted `dedicated=batch:NoSchedule` | Running on workers with a toleration (taints stay) |
| S04 | Scaled to 5, two replicas stay `Pending` | 2 | ns | required podAntiAffinity per hostname, 3 workers | 5 Running (preferred anti-affinity or spread) |
| S05 | `Pending` although the cluster is half empty | 3 | ns | topologySpreadConstraints `zone`, maxSkew 1, DoNotSchedule; zones uneven (zone-a: w1, w2; zone-b: w3) | all Running, spread constraint kept (ScheduleAnyway or labels fixed) |
| S06 | Pods `Pending` after maintenance: "unschedulable" | 1 | ns | all workers cordoned | Running; nodes uncordoned |
| S07 | Pod `Pending` forever, **no events at all** | 2 | ns | `schedulerName: custom-scheduler` (doesn't exist) | Running via default scheduler |
| S08 | Pod never scheduled, not even `Pending` events, node name looks right | 2 | ns | `nodeName: k8s-w4` (the spare VM, never joined) | Running |
| S09 | Log agent missing on the control-plane node | 1 | ns | DaemonSet without control-plane toleration | DS desired = number of nodes (4) |
| S10 | Web pods evicted whenever the batch job starts | 3 | ns | batch PriorityClass 1e6 + preemption, web has none | batch runs without preempting web (PriorityClass/preemptionPolicy) |
| S11 | `Pending`: "didn't have free ports for the requested pod ports" | 2 | ns | `hostPort: 8080` used by a DaemonSet | all Running (no hostPort or different) |
| S12 | `Pending`: "Too many pods" on an idle cluster | 2 | node | kubelet `maxPods: 8` on workers (`/var/lib/kubelet/config.yaml`) | all Running (maxPods raised) |
| S13 | Pod affinity Pending: wants to sit next to cache | 2 | ns | required podAffinity to label `app=cache` (pods are `app=redis-cache`) | Running co-located with cache |
| S14 | Pod requests GPU/extended resource, Pending | 2 | ns | `requests: example.com/gpu: 1`, no node advertises it | Running (resource advertised via node status patch or request removed per ticket) |

## R - Resources, QoS & autoscaling (10)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| R01 | HPA shows `<unknown>/60%`, never scales | 2 | ns | Deployment has no CPU requests | HPA shows a value, scales under load |
| R02 | `kubectl top` / HPA broken cluster-wide | 2 | ns | metrics-server args lose `--kubelet-insecure-tls` | `kubectl top nodes` works, HPA reads metrics |
| R03 | p99 latency 2 s, CPU graphs at 5% | 2 | ns | `limits.cpu: 50m` on a bursty service | p99 < 200 ms under load test (CPU limit raised/removed) |
| R04 | Pods evicted with "The node was low on resource: memory" | 2 | node | kubelet `evictionHard memory.available` raised on one worker; BestEffort pods | critical app Guaranteed QoS survives; no evictions 2 min |
| R05 | Pod rejected: "minimum cpu usage per Container is 200m" | 1 | ns | LimitRange min 200m, pod requests 100m | pods Running, LimitRange unchanged |
| R06 | Pod `Pending` while nodes are 10% utilised | 2 | ns | requests 3 CPU per replica "copied from VM sizing" | Running, requests right-sized (< 500m) |
| R07 | Workers report "fork: retry: Resource temporarily unavailable" | 3 | node | kubelet `podPidsLimit: 64`, app spawns 100 threads | stable, pods Ready |
| R08 | Node `DiskPressure`, pods evicted, images deleted | 2 | node | kubelet `evictionHard nodefs.available` set above current free | node condition false, pods back |
| R09 | HPA scales up/down every minute | 3 | ns | HPA `behavior` scaleDown stabilization 0 + spiky load | replica count stable during load test |
| R10 | Namespace quota: new deployment silently has 0 pods | 1 | ns | ResourceQuota `pods: 2` already used | new deployment Ready (quota adjusted per ticket) |

## W - Workload controllers (12)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| W01 | `kubectl rollout status` hangs forever | 1 | ns | new image tag broken, `progressDeadlineSeconds` long | working version live (undo or fix), no stuck RS |
| W02 | Can't apply new manifest: "spec.selector ... field is immutable" | 2 | ns | manifest changes `selector.matchLabels` | new version running under the new selector (recreated) |
| W03 | Half the requests hit the wrong app | 2 | ns | two Deployments share label `app=web`; Service selects both | only the intended app answers 20/20 |
| W04 | StatefulSet stuck at 1/3 replicas | 2 | ns | `web-0` fails readiness, OrderedReady blocks `web-1` | 3/3 Ready |
| W05 | `web-0.web` doesn't resolve | 2 | ns | StatefulSet `serviceName: web`, headless Service missing (ClusterIP named web-svc) | per-pod DNS resolves |
| W06 | DaemonSet missing on 2 nodes | 1 | ns | nodes tainted `maintenance=true:NoExecute` | DS on all nodes |
| W07 | Job failed: "BackoffLimitExceeded" | 1 | ns | wrong script path | Job Complete |
| W08 | Nightly CronJob didn't run | 2 | ns | `suspend: true` + previous Job stuck with `concurrencyPolicy: Forbid` | a scheduled run succeeds (test schedule every minute) |
| W09 | Image updated, nothing happens | 1 | ns | Deployment `paused` | new image running |
| W10 | `kubectl scale --replicas=2` keeps reverting to 5 | 2 | ns | HPA minReplicas 5 owns replicas | 2 replicas stable (HPA adjusted) |
| W11 | `kubectl rollout undo`: "no rollout history" | 2 | ns | `revisionHistoryLimit: 0` + broken current version | previous version live; history limit restored |
| W12 | `kubectl drain` hangs: "Cannot evict pod as it would violate the disruption budget" | 2 | ns | PDB minAvailable = replicas (3) | node drained & uncordoned, app stayed available |

## N - Services & DNS (14)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| N01 | Service times out, pods healthy | 1 | ns | selector `app: backend` vs pod label `app: back-end` | endpoints populated, curl-probe 200 |
| N02 | `connection refused` via Service, pod works via its IP:8080 | 1 | ns | `targetPort: 80`, container listens 8080 | curl-probe 200 |
| N03 | Service has endpoints but connections fail | 2 | ns | `targetPort: http`, container port named `web` | curl-probe 200 |
| N04 | NodePort works on some nodes only | 2 | ns | `externalTrafficPolicy: Local`, pods on one node | NodePort answers on every node (Cluster, or DaemonSet per ticket) |
| N05 | Pods in `frontend` can't reach `api` | 1 | ns | client uses `http://api` across namespaces | curl from frontend 200 (FQDN/short svc.ns) |
| N06 | Nothing resolves cluster-wide, CoreDNS `CrashLoopBackOff` | 2 | ns | Corefile `forward . 127.0.0.1` -> loop plugin aborts | CoreDNS Ready, cluster + external names resolve |
| N07 | Internal names resolve, external don't | 2 | ns | Corefile `forward . 10.255.255.1` (dead upstream) | external name resolves from a pod |
| N08 | Every external call costs 5 extra DNS queries, CoreDNS overloaded | 3 | ns | app calls `api.partner.example` (ndots:5 + 5 search domains); CoreDNS replica 1 with tight CPU | per-request queries <= 2 (FQDN with dot / ndots via dnsConfig), latency OK |
| N09 | Client sees only one backend instance | 2 | ns | app needs all pod IPs (headless) but Service is ClusterIP | client lists 3 peers |
| N10 | Migrated DB, app still connects to the old host | 2 | ns | selector-less Service + manual EndpointSlice with old IP | connects to new DB |
| N11 | Services broken only from pods on one node | 3 | cluster | kube-proxy pod excluded from `k8s-w2` (DaemonSet nodeAffinity) | Service reachable from every node |
| N12 | Pod-to-pod works on the same node, fails across nodes | 3 | node | nft rule on `k8s-w3` drops UDP 4789 (Calico VXLAN) | cross-node curl matrix all green |
| N13 | ExternalName service returns TLS / 404 errors | 3 | ns | ExternalName to a vhost; Host/SNI mismatch | request succeeds (Host header / proper Service) |
| N14 | `kubectl port-forward` works, Service doesn't (app bound to 127.0.0.1) | 2 | ns | app `--bind 127.0.0.1` | curl-probe via Service 200 |

## G - Ingress & Gateway API (8)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| G01 | Ingress returns 404 from the controller | 1 | ns | `ingressClassName: nginx` (cluster runs Traefik) | `curl -H Host:` through gateway 200 |
| G02 | Ingress 503 / "Service Unavailable" | 1 | ns | backend `service.port.number: 80`, Service port 8080 | 200 |
| G03 | `/api/items` 404 from the app behind Ingress | 2 | ns | Prefix `/api` without strip-prefix; app serves `/items` | 200 on `/api/items` |
| G04 | Browser gets "TRAEFIK DEFAULT CERT" | 2 | ns | TLS secret in wrong namespace / key-cert mismatch | valid lab-CA cert served for `shop.lab` |
| G05 | HTTPRoute ignored, `Accepted: False NotAllowedByListeners` | 2 | ns | Gateway listener `allowedRoutes: Same`, route in other ns | route Accepted, 200 |
| G06 | HTTPRoute `ResolvedRefs: False RefNotPermitted` | 2 | ns | backendRef to Service in another ns, no ReferenceGrant | 200 |
| G07 | Works by IP, 404 by hostname | 1 | ns | Ingress host `shop.lab` vs tested `www.shop.lab` | both hostnames 200 (per ticket) |
| G08 | Large uploads fail with 413 | 2 | ns | Traefik buffering middleware `maxRequestBodyBytes` 1 MiB | 10 MiB upload succeeds |

## X - NetworkPolicy & CNI (10)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| X01 | After "zero trust" rollout nothing resolves | 1 | ns | default-deny egress without DNS allow (UDP+TCP 53 to kube-system) | app works, default-deny kept |
| X02 | Frontend can't reach backend after policy | 1 | ns | ingress policy `podSelector` label typo | frontend->backend 200, others still blocked |
| X03 | Monitoring namespace blocked | 2 | ns | `namespaceSelector: team=monitoring`, namespace lacks label | monitoring allowed, others denied |
| X04 | Policy allows port 80, still blocked | 2 | ns | policy `port: 80` (Service port), pod listens 8080 | 200, only that port open |
| X05 | Policy too permissive: everyone in `monitoring` can reach DB | 3 | ns | `namespaceSelector` and `podSelector` as two list items (OR) | only prometheus pod allowed (AND) |
| X06 | Egress to external payment API blocked | 2 | ns | `ipBlock` with `except` covering the target | external endpoint reachable, everything else denied |
| X07 | New pods on one node have no network | 3 | cluster | calico-node DS `IP_AUTODETECTION_METHOD=first-found` + `updateStrategy: OnDelete`; only the `k8s-w3` pod restarted, so w3 registers the NAT `10.0.2.15` every VM shares | calico-node Ready everywhere, every node's Calico address on 192.168.56.0/24, matrix green |
| X08 | Pods stuck `ContainerCreating`: "failed to allocate IP" | 3 | cluster | Calico IPPool /26 with blockSize /29 exhausted | all pods Running (pool extended) |
| X09 | `shop` down after the "zero trust" rollout: DB password never arrives, DNS fails | 2 | ns | default-deny ingress+egress in `shop` and `external-secrets`; no allow for DNS or ESO → OpenBao `192.168.56.20:8200` | app Ready, ExternalSecret Ready, default-deny kept; only DNS + `192.168.56.20/32:8200` added (other egress still blocked) |
| X10 | Argo CD: every app `ComparisonError ... dial tcp 192.168.56.20:3000: i/o timeout` | 2 | ns | "hardening" default-deny egress in `argocd` allows DNS only; repo-server can't reach Gitea | apps Synced; repo-server egress = DNS + Gitea `:3000` only, policy kept |

## V - Storage (10)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| V01 | PVC `Pending` forever | 1 | ns | `storageClassName: fast-ssd` (doesn't exist) | Bound, pod Running |
| V02 | PVC `Pending`, "no persistent volumes available and no storage class is set" | 2 | ns | default-class annotation removed from local-path | Bound (default restored or class set) |
| V03 | Restored PV can't be reused | 2 | ns | PV `Released` with stale `claimRef`, Retain policy | new PVC Bound to that PV, data intact |
| V04 | Second replica `Pending`: "volume node affinity conflict" | 2 | ns | RWO local-path PVC shared by a 2-replica Deployment | app Ready (StatefulSet with per-pod PVC or 1 replica per ticket) |
| V05 | App: "permission denied" writing to its volume | 2 | ns | runAsUser 1000, volume root-owned, no fsGroup | writes succeed (fsGroup) |
| V06 | Can't grow StatefulSet disks: "updates to statefulset spec ... forbidden" | 3 | ns | change `volumeClaimTemplates` size | PVCs resized (expansion + `--cascade=orphan` recreate) |
| V07 | PVC resize request ignored | 2 | ns | nfs-csi StorageClass copy with `allowVolumeExpansion: false` | PVC capacity = requested |
| V08 | PVC stuck `Terminating` | 1 | ns | `kubernetes.io/pvc-protection` while a pod still mounts it | PVC deleted, app migrated per ticket |
| V09 | Pod stuck `ContainerCreating`: "hostPath type check failed" | 1 | ns | `hostPath type: Directory` for missing dir | Running (DirectoryOrCreate) |
| V10 | Data lost after every pod restart | 1 | ns | data on `emptyDir` | data survives pod deletion (PVC) |

## A - Security (13)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| A01 | App logs `pods is forbidden: User "system:serviceaccount:..." cannot list` | 1 | ns | RoleBinding in wrong namespace | `kubectl auth can-i list pods --as=sa` yes, nothing broader |
| A02 | Dev can `get pods` but not `kubectl exec` | 2 | ns | Role lacks `pods/exec` (create) | exec works for dev user, no cluster-admin |
| A03 | In-cluster client gets 401 | 2 | ns | `automountServiceAccountToken: false` on SA | API call 200 |
| A04 | Deployment has 0 pods, `kubectl get pods` empty | 2 | ns | namespace PSA `enforce=restricted`, pod privileged | pods Running, PSA stays restricted |
| A05 | `CreateContainerConfigError`: "image will run as root" | 1 | ns | `runAsNonRoot: true`, image USER root | Ready, still non-root |
| A06 | App crashes: "Read-only file system" | 1 | ns | `readOnlyRootFilesystem: true`, app writes `/tmp` | Ready, rootfs still read-only |
| A07 | Security audit: who can read Secrets? | 2 | ns | ClusterRoleBinding `secret-reader` -> `system:authenticated` | only intended SAs can read secrets |
| A08 | New engineer's kubeconfig: "x509: certificate signed by unknown authority" | 2 | ns | user cert signed by a wrong CA; task: issue via CSR API | user `alice` can list pods in `dev` |
| A09 | Nothing can be created in namespace `shop`: "failed calling webhook" | 3 | ns | ValidatingWebhook `failurePolicy: Fail` -> service without endpoints | creates work (webhook fixed or scoped), webhook kept |
| A10 | All new pods crash after "security sidecar" rollout | 3 | ns | MutatingWebhook injects env that breaks app | pods Ready, webhook fixed/excluded per ticket |
| A11 | CI token suddenly rejected after an hour | 2 | ns | short-lived TokenRequest; CI expects long-lived | API call with a durable token works |
| A12 | Job `secret-sync` fails: `secrets "db-creds" is forbidden`, yet the app pod mounting the same Secret is fine | 2 | ns | Job runs `kubectl get secret db-creds` as SA `syncer`; Role grants `get` with `resourceNames: [db-cred]` (typo) | Job Complete; `can-i get secret/db-creds` yes, `get` other Secrets / `list secrets` no |
| A13 | Who read the `payments` API key yesterday? | 3 | cluster | audit policy logs Secrets at `Metadata`; setup reads `payments/api-key` as SA `ci/reporter` from a pod and as user `bob` | answer file names both identities + time + source; policy still `Metadata` for Secrets (no values in the log) |

## K - Control plane (17, all `cluster` unless noted)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| K01 | `kubectl`: "connection to the server ... was refused" | 2 | cluster | apiserver manifest `--etcd-servers=https://127.0.0.1:2397` | apiserver healthy, `kubectl get nodes` works |
| K02 | apiserver gone after "hardening" (3 mistakes, one in metadata) | 3 | cluster | bad flag, wrong cert path, invalid label | healthy |
| K03 | New pods stay `Pending`, no scheduler events | 2 | cluster | scheduler manifest image typo | test pod scheduled |
| K04 | Deployments don't create pods, scale does nothing | 2 | cluster | controller-manager `--kubeconfig` path wrong | RS reconcile works |
| K05 | Whole control plane down after disk move | 3 | cluster | etcd `--data-dir` changed, hostPath not updated | etcd healthy, **data preserved** (old objects still there) |
| K06 | Namespace `prod` deleted by mistake - restore it | 3 | cluster | setup takes etcd snapshot, then deletes ns | `prod` objects back from snapshot |
| K07 | Everything x509-expired after "a long weekend" | 3 | cluster | kubeadm-config `certificateValidityPeriod: 15m` (v1beta4); certs renewed with it and left to expire | `kubeadm certs check-expiration` all > 300 d, no short validity left in kubeadm-config, cluster healthy |
| K08 | Your kubectl stopped working, others' works | 1 | ns | kubeconfig: wrong port / context namespace / user | `kubectl get pods -A` works with your kubeconfig |
| K09 | apiserver crashloops after enabling audit logging | 2 | cluster | `--audit-log-path` dir not mounted (hostPath missing) | apiserver healthy, audit log written |
| K10 | scheduler "disappeared", no pod in kube-system | 2 | cluster | YAML indentation error -> kubelet ignores manifest | scheduler pod running |
| K11 | Writes fail: "etcdserver: mvcc: database space exceeded" | 3 | cluster | etcd `--quota-backend-bytes=64Mi` + bulk ConfigMaps | alarm disarmed, compact + defrag, writes OK |
| K12 | CSRs stay `Pending` forever after approval | 3 | cluster | controller-manager missing `--cluster-signing-*` flags | approved CSR gets a certificate |
| K13 | Upgrade the cluster 1.36 → 1.37 (kubeadm) without app downtime | 3 | rebuild | `version: 1.36` (cluster rebuilt at 1.36; 1.37 debs cached on the nodes); labapp with a PDB under a probe | every node `v1.37.x` (control plane + kubelets), all uncordoned, probe saw no outage > 5 s |
| K14 | `kubectl` from the desktop hangs; workers go NotReady one by one; fine on `k8s-cp1` | 2 | cluster | haproxy on `k8s-gw`: API backend → `192.168.56.22:6443` (reserved cp2, no VM) | desktop kubectl via `k8s-api.lab:6443` works, workers Ready, haproxy backend UP |
| K15 | New worker `k8s-w4` won't join | 2 | cluster | join command in the ticket: expired token + `--discovery-token-ca-cert-hash` of an old CA; needs the spare VM (`k8slab.bat create k8s-w4`) | `k8s-w4` Ready with zone label, no non-expiring token left (`kubeadm token list`) |
| K16 | apiserver down after enabling encryption at rest | 3 | cluster | `--encryption-provider-config` added; aescbc key is 31 bytes and the file sits in a dir that isn't a hostPath mount | apiserver healthy; new **and** pre-existing Secrets stored `k8s:enc:aescbc:v1:` in etcd |
| K17 | `x509: certificate is valid for ..., not k8s-api.lab` from the desktop and the workers | 2 | cluster | apiserver cert re-issued without `k8s-api.lab` and `192.168.56.20` (certSANs dropped from kubeadm-config) | both SANs in the cert **and** in kubeadm-config; desktop kubectl + workers OK |

## L - Nodes & runtime (18, all `node`)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| L01 | `k8s-w2` `NotReady` | 1 | node | `systemctl stop kubelet` (and `disable`) on node | node Ready, kubelet enabled |
| L02 | Node NotReady: "container runtime is down" | 2 | node | containerd stopped / socket path changed in kubelet flags | Ready |
| L03 | kubelet crashloops after config change | 2 | node | `cgroupDriver: cgroupfs` in kubelet config (runtime uses systemd) | Ready |
| L04 | Node NotReady: "network plugin is not ready: cni config uninitialized" | 2 | node | `/etc/cni/net.d/*` removed on node | Ready, pods networked |
| L05 | Node NotReady after "control-plane IP change" | 2 | node | kubelet.conf server URL wrong port | Ready |
| L06 | `kubectl logs/exec` fail for pods on one node, pods run fine | 3 | node | `--node-ip` dropped from `kubeadm-flags.env` on `k8s-w2`: InternalIP becomes the NAT `10.0.2.15` every VM shares | w2 InternalIP 192.168.56.32, logs/exec work on all nodes |
| L07 | Pods on one node `ContainerCreating`: sandbox image pull fails | 3 | node | containerd sandbox (pause) image -> unreachable registry | pods Running |
| L08 | Node flaps Ready/NotReady | 3 | node | `tc netem loss 30%` on node -> lease renewals fail | Ready stable 2 min |
| L09 | Images on one node never pull from the lab registry | 2 | node | containerd `hosts.toml` mirror misconfigured on node | pods Running there |
| L10 | Static pod keeps coming back after delete | 1 | node | rogue manifest in `/etc/kubernetes/manifests` on a worker | gone permanently |
| L11 | `k8s-w3` unreachable; web moved, but `db-0` is stuck `Terminating` for 10 min | 3 | node | nft `lab_fault` on w3 drops cluster peers (desktop ssh kept); StatefulSet `db` on an NFS PVC runs there | `db-0` Ready on another node with its data; old container on w3 stopped (fenced) before force delete / `out-of-service` taint |
| L12 | A node died and its pods took over an hour to move | 2 | node | Deployment tolerates `unreachable`/`not-ready` for 3600 s ("flap protection" copy-paste); setup partitions `k8s-w2` | after a fresh partition, replicas Ready elsewhere within 120 s; no blanket `operator: Exists` toleration |
| L13 | Everything on `k8s-w1` is slow, probes time out; `kubectl top` shows little CPU | 3 | node | systemd drop-in `CPUQuota=20%` on `kubepods.slice` on w1 | drop-in gone (`cpu.max` = max), no throttling, probes stable 2 min |
| L14 | `k8s-w2` NotReady after a routine reboot | 2 | node | swap file added to fstab, then `reboot`; kubelet `failSwapOn` | Ready after a verify-triggered reboot, `swapon --show` empty |
| L15 | Node audit after `k8s-w3`'s reboot: `net.bridge.bridge-nf-call-iptables` missing | 1 | node | `br_netfilter` dropped from `/etc/modules-load.d/k8s.conf`, then `reboot`; silent on routed Calico (no bridge), and kubeadm ≥ 1.30 no longer checks it | module loaded + bridge sysctls = 1 after a verify-triggered reboot |
| L16 | `k8s-w1` NotReady, kubelet logs `x509: certificate has expired or is not yet valid` | 2 | node | chrony stopped + disabled on w1, `date -s '-400 days'` | chrony enabled and synced to gw (offset < 1 s), node Ready |
| L17 | `k8s-w2` `DiskPressure`, pods evicted; `du` finds nothing big | 3 | node | `lab-logger` unit on w2 fills `/var` with a file it unlinks but keeps open | DiskPressure false, `/var` < 80%, unit stopped + disabled, pods Ready |
| L18 | Random new-connection timeouts from pods on `k8s-w3` only | 3 | node | `nf_conntrack_max=2048` via sysctl.d on w3 (re-set after kube-proxy start); load pod opens short connections | `nf_conntrack_max` ≥ 131072 and not lowered by sysctl.d, 2-min load with 0 conntrack drops |

## O - Cluster operations & API machinery (11; O12 moved to K13)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| O01 | Namespace stuck `Terminating` for days | 2 | ns | CR with finalizer, operator uninstalled | namespace gone (finalizer removed correctly) |
| O02 | Can't delete a custom resource | 2 | ns | finalizer + missing controller | CR gone, CRD kept |
| O03 | `apply`: "no matches for kind PodDisruptionBudget in version policy/v1beta1" | 1 | ns | manifests with removed APIs (PDB v1beta1, Ingress v1beta1) | objects created with current APIs |
| O04 | `helm upgrade`: "another operation is in progress" | 2 | ns | release secret left `pending-upgrade` | upgrade succeeds |
| O05 | `helm install`: "exists and cannot be imported into the current release" | 2 | ns | pre-existing Service without Helm ownership labels | release deployed, Service owned by release |
| O06 | Deleted the Deployment, pods still running | 1 | ns | delete with `--cascade=orphan` | no orphan RS/pods |
| O07 | Drain worker for maintenance (local data + DaemonSets) | 2 | ns | pods with emptyDir, DS, bare pod | node drained, apps rescheduled, node uncordoned |
| O08 | Prod got dev settings | 2 | ns | Kustomize overlay patch targets wrong name | prod overlay renders and deploys prod values |
| O09 | Who deleted the ConfigMap? | 3 | cluster | audit policy enabled; setup deletes as user `bob` | answer file names the user + time |
| O10 | `kubectl apply` conflict with field manager | 3 | ns | server-side apply conflict with another manager | change applied, ownership resolved |
| O11 | CRD upgrade broke `kubectl get` on old objects | 3 | ns | CRD `served: false` for the stored version | old objects readable/migrated |
| O12 | Upgrade the cluster one minor version (kubeadm) | - | - | moved to **K13** (real kubeadm upgrade on the VM cluster, reset `rebuild`) | see K13 |

## Q - Observability & forensics (5)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| Q01 | `kubectl logs` shows nothing, app "logs a lot" | 1 | ns | app logs to `/var/log/app.log` inside container | logs visible via `kubectl logs` (stdout or sidecar) |
| Q02 | Why did the pod restart at 03:00? | 1 | ns | OOM at a fixed time; task: answer file (reason, exit code, container) | answers correct |
| Q03 | Which pod is the noisy neighbour on `k8s-w1`? | 1 | ns | one pod burns CPU/memory | answer file correct (`kubectl top`, `crictl stats`) |
| Q04 | Events already gone - reconstruct the incident | 2 | ns | short event TTL; info in `lastState`, logs `--previous`, RS history | answers correct |
| Q05 | Find the failing request path from logs across 6 pods | 2 | ns | multi-pod logs | answer correct (`stern`/label-selector logs) |

## D - Delivery: Helm & Argo CD (12)

All apps come from the Gitea repo `lab/gitops` (charts `labapp`, `shop`; `envs/{dev,prod}`). "Fix in Git" = pushed
to `main` from `workspace/gitops`, not a live `kubectl` patch.

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| D01 | `labapp` broken right after a values change | 2 | ns | `envs/dev/values.yaml` key typo `servcie.targetPort: 8080` (silently ignored, chart default 80 used) + `image.tag: 1.4.0` | Synced/Healthy, curl-probe 200, fix in Git |
| D02 | Argo CD shows `labapp` OutOfSync: someone "hotfixed" prod | 2 | ns | `kubectl scale --replicas=1` + `kubectl set env FEATURE_X=on` on the live Deployment; auto-sync on, self-heal off | Synced; `FEATURE_X=on` now comes from Git (wanted per ticket), replicas = Git (3) |
| D03 | Auto-sync deployed a bad commit: Argo CD says Synced, the app is down | 2 | ns | commit to `main` with image `labapp:2.0.0-rc1` (crashes on start): sync OK, health `Degraded` | `main` reverted, Synced + Healthy, auto-sync still on |
| D04 | `payments` won't sync: "application destination ... is not permitted in project" | 2 | ns | AppProject `team-a` destinations lack namespace `payments`; `clusterResourceWhitelist` empty but the app ships its Namespace | Synced/Healthy; `team-a` still denied `kube-system` and other cluster-scoped kinds |
| D05 | Every app `Unknown`: "repository not accessible: authentication required" | 1 | ns | Gitea password of `argocd` rotated; repo Secret still holds the old one | repo connection Successful, apps Synced, credentials only in the repo Secret |
| D06 | `labapp` flips OutOfSync every few minutes, nobody touched it | 2 | ns | chart renders `replicas: 2` while an HPA scales the Deployment; self-heal fights the HPA | Synced for 5 min under load, HPA owns replicas (field dropped from Git or `ignoreDifferences`) |
| D07 | Sync fails: "spec.selector: Invalid value ... field is immutable" | 2 | ns | chart bump adds `app.kubernetes.io/version` to `selector.matchLabels` | Synced/Healthy; selector stable across versions (chart fixed, not `Replace=true`) |
| D08 | On-call ran `helm rollback`; it worked for a minute, then broke again | 2 | ns | release installed by `helm`, later adopted by an Argo CD app with self-heal; bad commit live | `main` reverted, Synced/Healthy 2 min, stale `sh.helm.release.v1` Secrets removed |
| D09 | Sync stuck `Running`: "waiting for completion of hook batch/Job/db-migrate" | 2 | ns | PreSync migration Job reads Secret `db-creds`, which is created only in the Sync phase | sync Succeeded, migration Job Completed, re-sync works (hook delete policy) |
| D10 | Prod pods run with dev settings (1 replica, debug logs) | 2 | ns | prod Application `valueFiles: [envs/prod/values.yaml, envs/dev/values.yaml]` (last wins) | prod renders prod values (3 replicas, `LOG_LEVEL=info`), dev unchanged |
| D11 | New `metrics` app merged a day ago - Argo CD doesn't know it exists | 2 | ns | child Application committed under `apps/team/metrics.yaml`; root app-of-apps has `directory.recurse: false` | `metrics` Application exists in `argocd`, Synced/Healthy; root still Synced |
| D12 | After a cleanup commit the database came back empty | 3 | ns | auto-sync `prune: true`; commit drops the PVC from the chart; pruned on the next rollout; PV `Released` (Retain) | same PV re-bound, data intact, PVC back in Git with `Prune=false`, app Synced |

## Y - Secrets (10)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| Y01 | `labapp` in `prod`: secret `db-creds` not found, though the SealedSecret is in Git | 2 | ns | SealedSecret sealed (strict scope) for namespace `dev`, committed under `envs/prod`: "no key could decrypt secret" | Secret `db-creds` in `prod` (resealed for `prod`, still strict), pod Ready, no plaintext in Git |
| Y02 | After the cluster rebuild every SealedSecret fails to decrypt | 3 | cluster | sealing key Secrets deleted + controller restarted (new key generated); backup in `.state/sealed-secrets-key.yaml` | old key restored + controller restarted, all SealedSecrets Synced, Git untouched (no reseal) |
| Y03 | ExternalSecret `SecretSyncedError`, app has no DB password | 2 | ns | `remoteRef.key: labapp/database`; the kv-v2 secret lives at `labapp/db` | ExternalSecret Ready, Secret keys present (values not printed), pod Ready, fix in Git |
| Y04 | ExternalSecrets in `prod` fail: OpenBao `permission denied` | 2 | ns | OpenBao role `prod` bound to SA `default`; the SecretStore authenticates as `eso-reader` | store + ExternalSecrets Ready; role bound to exactly `prod/eso-reader` (no `*`) |
| Y05 | ClusterSecretStore not Ready: "x509: certificate signed by unknown authority" | 2 | ns | `caProvider` ConfigMap `lab-ca` holds a pre-rotation lab CA | store Ready over `https://` with `caProvider` = current lab CA |
| Y06 | All ExternalSecrets failing since gateway maintenance | 1 | ns | `systemctl restart openbao` on `k8s-gw`: it comes back sealed | OpenBao unsealed, ExternalSecrets Ready after a forced refresh |
| Y07 | Rotated the DB password in OpenBao an hour ago; app still logs in with the old one | 2 | ns | ESO already refreshed the Secret; app reads it via `env` and never restarts | app authenticates with the new password; pods roll on Secret change (hash annotation or mounted file) |
| Y08 | Secret `api-key` flips between two values every minute | 3 | ns | legacy and new ExternalSecret both target `api-key` with `creationPolicy: Merge` | one ExternalSecret owns `api-key` (`Owner`), value stable 3 min, legacy one gone from Git |
| Y09 | New teammate can't decrypt `secrets/prod.enc.yaml`: sops finds no key | 2 | ns | teammate's age recipient added to `.sops.yaml`; `sops updatekeys` never run on existing files | file decrypts with the teammate's and the team key, content unchanged |
| Y10 | Security scan: plaintext password in Git (`secrets/new-service.enc.yaml`) | 2 | ns | `.sops.yaml` `encrypted_regex: ^data$`; the file uses `stringData`, so it is committed with sops metadata but plaintext values | HEAD has no plaintext, rule covers `data` + `stringData`, leaked password rotated (old value rejected) |

## B - Boss fights (7, multi-fault)

| ID | Ticket | Lvl | Reset | Emulation (faults) | Verify |
|---|---|---|---|---|---|
| B01 | Black Friday: shop down | 3 | ns | Service selector + NetworkPolicy DNS + HPA without requests + PDB | shop 200 under load, HPA scales, a drain succeeds, default-deny kept |
| B02 | Control-plane meltdown after "hardening" | 3 | cluster | scheduler manifest + controller-manager kubeconfig + one node kubelet | `doctor` green |
| B03 | Onboard team `payments` - nothing deploys | 3 | ns | ResourceQuota + PSA restricted + RBAC + default-deny | payments app Running under quota, PSA restricted, namespaced RBAC, default-deny + DNS allow |
| B04 | Postgres migration | 3 | ns | PVC class + fsGroup + StatefulSet headless service + secret key | postgres Ready on its PVC, per-pod DNS, app connects, data intact |
| B05 | "Works in staging" | 3 | ns | image arch + missing imagePullSecret + Ingress class + ConfigMap namespace | pods Ready, Ingress 200, config loaded |
| B06 | Disaster recovery | 3 | cluster | etcd restore + certificate expiry + app data check | `prod` objects back, certs valid, app data checksum matches |
| B07 | GitOps DR: "rebuilt" cluster, nothing comes back | 3 | cluster | Argo CD repo Secret gone + sealing key regenerated (backup in `.state`) + OpenBao sealed + root app `targetRevision: master` (branch is `main`) | every app Synced/Healthy; SealedSecrets decrypt with the restored key (Git untouched); ExternalSecrets Ready; labapp 200 |

---

### Research scenarios

The 8 scenarios proposed in `kubernetes_lab_research_english.md`; all are in wave 1.

| # | Research scenario | ID |
|---|---|---|
| 1 | Faulty Helm chart deployment | D01 |
| 2 | Argo CD configuration drift | D02 |
| 3 | Broken automatic synchronization | D03 |
| 4 | Argo CD authorization failure | D04 |
| 5 | Incorrectly sealed Secret | Y01 |
| 6 | ExternalSecret provider failure | Y03 |
| 7 | Secret access forbidden by RBAC | A12 |
| 8 | NetworkPolicy blocks service access | X09 |

### Learn track (`learn/T01-T16`)

Guided tasks with `./lab verify`, no spoilers needed. "T" because "L" is the nodes domain.

| ID | Topic | What you do | Leads into |
|---|---|---|---|
| T01 | Lab tour and kit | `./lab ui`, `./lab env`, `./lab node`, haproxy on gw, the reset ladder; a first Deployment + Service | all |
| T02 | kubeadm anatomy | static pods, `/etc/kubernetes` + pki, kubelet config, kubeadm-config | K01-K12 |
| T03 | Join `k8s-w3` back by hand | setup drains/deletes/resets w3; token + CA hash, `--node-ip` (NAT trap), serving CSR, zone label | K15 |
| T04 | Packet path pod → svc → node | Calico routes + VXLAN, kube-proxy rules, conntrack, tcpdump on nodes | N11, N12, X07, L18 |
| T05 | Storage: local vs NFS RWX | local-path node affinity, nfs-csi RWX, snapshots, reclaim | V01-V10, L11 |
| T06 | MetalLB + Ingress/Gateway | L2 pool, Traefik Ingress, Gateway + HTTPRoute | G01-G08 |
| T07 | RBAC + CSR users | Roles, `can-i`, user cert via the CSR API, SA tokens | A01-A08, A12 |
| T08 | etcd backup/restore | `etcdctl snapshot save`, `etcdutl snapshot restore` | K05, K06, B06 |
| T09 | kubeadm upgrade | setup: bare 1.36 cluster (`cluster_bare_build`, PKI kept); guided 1.36 → 1.37 with drain/uncordon | K13 |
| T10 | Helm | chart anatomy, values precedence, template/lint, failed upgrade (`--wait`), rollback, release Secrets | D01, D07, D10, O04, O05 |
| T11 | Argo CD | Application, sync vs health, auto-sync + self-heal, AppProject, app-of-apps | D02-D12 |
| T12 | Sealed Secrets | `kubeseal` scopes, key backup, key-loss drill and restore | Y01, Y02 |
| T13 | ESO + OpenBao | kv-v2, least-privilege policy + kubernetes auth role, namespaced SecretStore with `caProvider`, rotation | Y03-Y08 |
| T14 | SOPS + age | `.sops.yaml` rules, encrypt/decrypt, `updatekeys` | Y09, Y10 |
| T15 | NetworkPolicy for a GitOps stack | default-deny + DNS in shop, app flows, ESO/Argo CD egress incl. the API's post-DNAT endpoint | X09, X10 |
| T16 | Hardening | encryption at rest, audit policy, PSA | K16, A13, A04 |

### Totals
| Domain | P | C | S | R | W | N | G | X | V | A | K | L | O | Q | D | Y | B | **Sum** |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Count | 16 | 8 | 14 | 10 | 12 | 14 | 8 | 10 | 10 | 13 | 17 | 18 | 11 | 5 | 12 | 10 | 7 | **195** |

Plus 16 learn labs (T01-T16). O12 only points to K13 and is not counted.

### Backlog (more research needed)
HA control plane (cp2/cp3 at .22/.23 are reserved: etcd member add/remove, LB failover), conntrack DNS race
(5 s, glibc/musl), real `poweroff` node loss (optional, not selftested: you start the VM in VirtualBox),
Argo CD CMP/KSOPS for in-cluster SOPS, cert-manager, multi-cluster, service mesh (Istio/Linkerd mTLS),
Velero backup/restore.
