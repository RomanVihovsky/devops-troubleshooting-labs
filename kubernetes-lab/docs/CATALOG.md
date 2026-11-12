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
| P02 | Private image can't be pulled, public ones fine | 2 | ns | image on `registry.lab:5001` (htpasswd, user ci; `imagePullPolicy: Always`, no cached copies); the working `regcred` lives in namespace `ci` | 2 Ready on the :5001 image; pulled with a pull Secret in `vendor`; anonymous pulls still refused |
| P03 | Pod crashes instantly: `exec format error` | 2 | ns | `labapp:1.6` = arm64 python image (single-arch manifest) under an ordinary tag | 2 Ready, stable 30 s, on a `lab/labapp` image built for linux/amd64 (crane config on gw) |
| P04 | `CrashLoopBackOff` right after deploy, works in dev | 1 | ns | labapp exits 1 when `DATABASE_URL` missing; env var renamed `DB_URL` in manifest | Ready, no new restarts for 60 s, `REQUIRED_ENV` unchanged |
| P05 | `CrashLoopBackOff`, but the logs say "done" and exit code 0 | 2 | ns | `labapp migrate` (exits 0) run as a Deployment | a Job running migrate Completed; no Deployment/STS/DS runs it; web 2 Ready |
| P06 | `CreateContainerConfigError` | 1 | ns | `secretKeyRef` key `password` but Secret has `passwd` | pods Ready, secret value unchanged |
| P07 | `RunContainerError: exec: "gunicorn": executable file not found` | 1 | ns | `command:` overrides entrypoint with a binary not in the image | pods Ready, same image (`labapp:1.4`) |
| P08 | Pods restart under load, `Last State: OOMKilled` (137) | 1 | ns | labapp cache 192 Mi, limit 128 Mi | Ready, no new restarts for 60 s, `CACHE_MB` unchanged |
| P09 | Healthy app killed every ~30 s | 1 | ns | liveness probe on port 8081 (app listens 8080) | no liveness kills for 60 s, liveness still present |
| P10 | Pods Running but `0/1 Ready`; Service times out | 1 | ns | readiness `/healthz` (app serves `/health`) | Ready; Service endpoints populated; curl-probe 200 |
| P11 | Pods never get past startup on big datasets | 2 | ns | app needs 45 s warm-up; liveness initialDelay 10 s, no startupProbe | Ready, no new restarts for 60 s, liveness and the 45 s warm-up unchanged (startupProbe added) |
| P12 | Pods stuck in `Init:0/1` | 1 | ns | init container waits for `nslookup postgres` (service is `postgresql`) | Running/Ready, init container still present |
| P13 | `kubectl delete pod` hangs, pod stays `Terminating` | 2 | ns + cleanup.sh | orphaned finalizer `example.com/cleanup` + `SHUTDOWN_MODE=ignore`, grace 600 s | no pod Terminating or with the finalizer; 1 Ready; SHUTDOWN_MODE not ignore, grace <= 60 s |
| P14 | Job never reaches Completed although the work is done | 3 | ns | Job with a log-shipper sidecar as a regular container (never exits) | Job Complete (native sidecar `restartPolicy: Always` initContainer) |
| P15 | Pod `Evicted`: "ephemeral local storage usage exceeds the total limit" | 2 | ns | 300 MiB disk cache in the writable layer, `ephemeral-storage` limit 100Mi | DISK_CACHE_MB still 300; `/cache` = emptyDir with sizeLimit >= 300Mi or a PVC; 2 Ready, no new evictions for 60 s |
| P16 | Graceful shutdown drops in-flight requests during rollouts | 3 | ns | no `preStop`, app exits before endpoints removed; load test shows 5xx during rollout | rollout under load with 0 errors (preStop sleep / terminationGrace) |

## C - Configuration (8)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| C01 | Changed the ConfigMap, the app still says the old greeting | 1 | ns | `GREETING` via `envFrom` from `promo-config`; the ConfigMap changed to Bonjour after the pods started | every pod says Bonjour; GREETING still from the ConfigMap (no literal) |
| C02 | The mounted config file never updates in running pods | 2 | ns | `CONFIG_FILE` (re-read per request) mounted with `subPath`; the ConfigMap edited afterwards | every pod says Bonjour; the test edits the ConfigMap again and every pod follows **without** a restart or replacement |
| C03 | App says "invalid password" (WRONGPASS), the Secret looks right | 2 | ns | `cart-redis` `data:` holds base64 of the base64 password | cart 2 Ready with `/ready` redis ok; `cart-redis` decodes to `redis-auth`'s password; Redis still requires it |
| C04 | nginx crash-loops: `mime.types` not found | 2 | ns | ConfigMap `nginx-conf` mounted **as** `/etc/nginx` (hides the image's files); `lab/nginx:1.30-alpine` | 2 Ready; 200 with the custom `X-Served-By: web-c04`; the image's own mime.types in use |
| C05 | `CreateContainerConfigError: configmap "app-config" not found` - but it exists | 1 | ns | the runbook file has no namespace: the ConfigMap landed in `default` | checkout 2 Ready greeting Hej; still from ConfigMap `app-config` |
| C06 | Can't apply a config change: "field is immutable" | 2 | ns | `pricing-config` is `immutable: true`; CURRENCY EUR → USD rejected | every pod `CURRENCY=USD`; the ConfigMap in use is immutable and says USD |
| C07 | Auth header rejected only in Kubernetes | 3 | ns | Secret created `--from-file` with trailing newline; app sends `Bearer token\n` | upstream returns 200 |
| C08 | Downward API manifest rejected, then the memory limit is wrong | 2 | ns | `fieldPath: status.podIp` (rejected by the API); `resourceFieldRef limits.memory` without a limit (= node memory) | 2 Ready; per pod `POD_IP` = its IP and `MEMORY_LIMIT_MB` = 256; both still Downward API |

## S - Scheduling (14)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| S01 | New pods `Pending`: "Insufficient cpu" | 1 | ns | `requests.cpu: "16"` | Running, requests realistic (< 1 CPU) |
| S02 | `Pending`: "didn't match Pod's node affinity/selector" | 1 | ns | `nodeSelector: disktype: ssd`, nodes labelled `disk=ssd` | Running on the ssd node |
| S03 | `Pending`: "untolerated taint" | 1 | ns | all workers tainted `dedicated=batch:NoSchedule` | Running on workers with a toleration (taints stay) |
| S04 | Scaled to 5, two replicas stay `Pending` | 2 | ns | required podAntiAffinity per hostname, 3 workers | 5 Ready, on all 3 workers (soft spread or preferred anti-affinity) |
| S05 | `Pending` although the cluster is half empty | 3 | ns | topologySpreadConstraints `zone`, maxSkew 1, DoNotSchedule; zones uneven (zone-a: w1, w2; zone-b: w3) | all Running, spread constraint kept (ScheduleAnyway or labels fixed) |
| S06 | Pods `Pending` after maintenance: "unschedulable" | 1 | ns | all workers cordoned | Running; nodes uncordoned |
| S07 | Pod `Pending` forever, **no events at all** | 2 | ns | `schedulerName: custom-scheduler` (doesn't exist) | Running via default scheduler |
| S08 | Pod never scheduled, not even `Pending` events, node name looks right | 2 | ns | `nodeName: k8s-w4` (the spare VM, never joined) | Running |
| S09 | Log agent missing on the control-plane node | 1 | ns | DaemonSet without control-plane toleration | DS desired = number of nodes (4) |
| S10 | Web pods evicted whenever the batch job starts | 3 | ns | batch PriorityClass 1e6 + preemption, web has none | batch runs without preempting web (PriorityClass/preemptionPolicy) |
| S11 | `Pending`: "didn't have free ports for the requested pod ports" | 2 | ns | `hostPort: 8080` used by a DaemonSet | edge-proxy Ready and serving; node-probe keeps hostPort 9100 on every worker |
| S12 | `Pending`: "Too many pods" on a half-idle cluster | 2 | node (w1-w3) | each worker's kubelet `maxPods` = the pods it runs now (a fixed 8 would make the kubelet reject running pods) | `reports` 3 Running; every worker maxPods >= 110 in config.yaml and reported |
| S13 | session-api Pending: wants to sit next to the cache | 2 | ns | required podAffinity to `app=cache` (the pods are `app=redis-cache`) | 2 Running on the cache's node; still **required** affinity |
| S14 | trainer Pending: "Insufficient example.com/gpu" | 2 | ns + cleanup.sh | requests `example.com/gpu: 1`; nothing advertises it (device plugin "next week") | w3 advertises `example.com/gpu: 2` (status patch); trainer Running on w3, request kept |

## R - Resources, QoS & autoscaling (10)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| R01 | HPA shows `<unknown>/60%`, never scales | 2 | ns | HPA on CPU utilization; the container has no CPU request | the HPA reports a CPU value; under the test's 2-min load it scales beyond 1; target 60%, range 1-5 kept |
| R02 | `kubectl top` / every HPA broken cluster-wide | 2 | ns + cleanup.sh | metrics-server `--kubelet-preferred-address-types=Hostname` (pods can't resolve node names). `--kubelet-insecure-tls` was never set here: the kubelets have verified serving certs | `kubectl top nodes` lists 4; InternalIP first; still no `--kubelet-insecure-tls` |
| R03 | p99 latency of seconds, CPU graphs at 5% | 2 | ns | `limits.cpu: 50m`, ~20 ms of PBKDF2 per request (`HASH_ITERATIONS`) | 20 rps × 20 s: p99 < 200 ms, no errors; limit >= 500m or none; request kept |
| R04 | Pods evicted on w2: "The node was low on resource: memory" | 2 | node (w2) | kubelet `evictionHard memory.available` = free memory + 300Mi (computed at setup) | no MemoryPressure; threshold <= 500Mi (or default); payments-api 2 Ready, **Guaranteed**, on w2, stable 60 s |
| R05 | Deployment has 0 pods: "minimum cpu usage per Container is 200m" | 1 | ns | LimitRange min cpu 200m, the pods request 100m | worker 2 Ready; LimitRange unchanged |
| R06 | `Pending` while the nodes are mostly idle | 2 | ns | memory requests 6Gi ("from the 8 GB VM") on 4 GiB nodes | 2 Running; memory request <= 512Mi, request + limit set |
| R07 | Workers report "fork: retry: Resource temporarily unavailable" | 3 | node | kubelet `podPidsLimit: 64`, app spawns 100 threads | stable, pods Ready |
| R08 | w3 DiskPressure, pods evicted, images deleted, disk 3/4 empty | 2 | node (w3) | kubelet `evictionHard nodefs.available` = free% + 5 (computed at setup) | no DiskPressure; threshold <= 15% (or default); ingest 2 Ready on w3 |
| R09 | HPA scales up/down every minute | 3 | ns | HPA `behavior` scaleDown stabilization 0 + spiky load | replica count stable during load test |
| R10 | Namespace quota: the new deployment silently has 0 pods | 1 | ns | ResourceQuota `pods: 2`, used by `legacy` | notifier 1 Ready; quota pods = 5 (as approved), the rest unchanged |

## W - Workload controllers (12)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| W01 | `kubectl rollout status` hangs forever | 1 | ns | 1.5 (exits) with `maxUnavailable: 0`, `progressDeadlineSeconds: 3600` | 3 Ready on a working version, no RS with unready pods, deadline <= 600 |
| W02 | Can't apply v2: "spec.selector ... field is immutable" | 2 | ns | v2 adds `tier: web` to the selector | Deployment `search` with the v2 selector, 2 Ready saying "Search v2", Service answers |
| W03 | Half the requests hit the wrong app | 2 | ns | `admin` (copied from web) keeps `app: web`; Service selects `app: web` | 20/20 through Service web answered by web; admin still runs |
| W04 | StatefulSet stuck at 1/3 | 2 | ns | readiness on `/readyz` (404): OrderedReady never creates member 1 | 3/3 Ready, still OrderedReady + a readiness probe |
| W05 | `web-0.web` doesn't resolve | 2 | ns | `serviceName: web`, only a ClusterIP Service `web-svc` | `web-0/1/2.web.kv.svc.cluster.local` resolve to their pods; web-svc still answers |
| W06 | log-agent DaemonSet missing on 2 workers | 1 | ns | w1, w2 tainted `maintenance=true:NoExecute` | log-agent Ready on w1-w3; the taints stay |
| W07 | Job failed: "BackoffLimitExceeded" | 1 | ns | `sh /script/report.sh`, ConfigMap mounted at `/scripts` | Job Complete, log "report done", script still from the ConfigMap |
| W08 | The nightly CronJob didn't run | 2 | ns | a hung run (`sleep 3600`) blocks `Forbid`; then `suspend: true` | a Job created after setup succeeded; not suspended, schedule + Forbid kept; nothing running > 2 min |
| W09 | Image updated, nothing happens | 1 | ns | `rollout pause`, then `set image` 1.3 → 1.4 | not paused; 3 Ready all on 1.4 |
| W10 | `kubectl scale --replicas=2` keeps reverting to 5 | 2 | ns | HPA `minReplicas: 5` owns replicas | one HPA min <= 2, max >= 10; 2 Ready for 60 s |
| W11 | `rollout undo`: "no rollout history" | 2 | ns | `revisionHistoryLimit: 0` + `Recreate`; 1.3 → 1.5 (crashes) | 3 Ready on 1.3; revisionHistoryLimit >= 2 |
| W12 | `kubectl drain` hangs: PDB violation | 2 | ns | PDB minAvailable 3 = replicas (required anti-affinity, one per worker); setup's drain attempt left w1 cordoned | the w1 pod evicted, w1 schedulable, 3 Ready, PDB still guarantees 2 |

## N - Services & DNS (14)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| N01 | Service times out, pods healthy | 1 | ns | selector `app: backend` vs pod label `app: back-end` | endpoints populated, curl-probe 200 |
| N02 | `connection refused` via Service, pod works via its IP:8080 | 1 | ns | `targetPort: 80`, container listens 8080 | curl-probe 200 |
| N03 | Service has endpoints but connections fail | 2 | ns | `targetPort: http`, container port named `web` | curl-probe 200 |
| N04 | NodePort works on some nodes only | 2 | ns | `externalTrafficPolicy: Local`, pods on one node | NodePort 30480 answers 200 on every worker, from the desktop |
| N05 | Pods in `frontend` can't reach `api` | 1 | ns | client uses `http://api` across namespaces | curl from frontend 200 (FQDN/short svc.ns) |
| N06 | Nothing resolves cluster-wide, CoreDNS `CrashLoopBackOff` | 2 | ns | Corefile `forward . 127.0.0.1` -> loop plugin aborts | CoreDNS Ready, cluster + external names resolve |
| N07 | Internal names resolve, external don't | 2 | ns | Corefile `forward . 10.255.255.1` (dead upstream) | external name resolves from a pod |
| N08 | Every external call costs 5 extra DNS queries, CoreDNS overloaded | 3 | ns | app calls `api.partner.example` (ndots:5 + 5 search domains); CoreDNS replica 1 with tight CPU | per-request queries <= 2 (FQDN with dot / ndots via dnsConfig), latency OK |
| N09 | Client sees only one backend instance | 2 | ns | app needs all pod IPs (headless) but Service is ClusterIP | client lists 3 peers |
| N10 | Migrated the DB, the app still connects to the old host | 2 | ns | Service `db` without selector + hand-made EndpointSlice to the old postgres pod; the old DB scaled to 0 | orders 2 Ready with postgres ok; `db` leads only to pg-new; `db:5432` unchanged; old DB stays off |
| N11 | Services broken only from pods on one node | 3 | cluster | kube-proxy pod excluded from `k8s-w2` (DaemonSet nodeAffinity) | Service reachable from every node |
| N12 | Pod-to-pod works on the same node, fails across nodes | 3 | node | nft rule on `k8s-w3` drops UDP 4789 (Calico VXLAN) | cross-node curl matrix all green |
| N13 | ExternalName service returns TLS / 404 errors | 3 | ns | ExternalName to a vhost; Host/SNI mismatch | request succeeds (Host header / proper Service) |
| N14 | `kubectl port-forward` works, Service doesn't (app bound to 127.0.0.1) | 2 | ns | app `--bind 127.0.0.1` | curl-probe via Service 200 |

## G - Ingress & Gateway API (8)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| G01 | Ingress returns 404 from the controller | 1 | ns | `ingressClassName: nginx` (the cluster runs Traefik) | gallery.lab 200 from the app, through an Ingress |
| G02 | Ingress 404, Traefik logs "service port not found" | 1 | ns | backend `service.port.number: 80`, the Service has 8080 (Traefik skips the route: 404; ingress-nginx would answer 503) | catalog.lab 200; Service still on 8080 |
| G03 | `/api/items` 404 from the app behind the Ingress | 2 | ns | Prefix `/api`, ingress-nginx `rewrite-target` annotation (Traefik ignores it); app serves `/items` | `/api/items` 200 with the items; the app has no BASE_PATH (StripPrefix middleware) |
| G04 | Browser gets "TRAEFIK DEFAULT CERT" | 2 | ns + cleanup.sh | TLS Secret `secure-tls` created in `default`, the Ingress is in `secure` | https://secure.lab 200 with a cert for secure.lab verified by the lab CA |
| G05 | HTTPRoute ignored, `Accepted: False NotAllowedByListeners` | 2 | ns | the team's own Gateway (`gw-infra/team`, `*.team.lab` on web:8000) with `allowedRoutes: Same`; route in `gw-shop` | route Accepted, shop.team.lab 200; Gateway admits by label `gateway-access: team`; gw-other still refused |
| G06 | HTTPRoute `ResolvedRefs: False RefNotPermitted` | 2 | ns | route in `web-front` → Service in `web-back`, no ReferenceGrant | refs resolve, frontdoor.lab answers from web-back/api, backend still in web-back |
| G07 | Works by the bare name, 404 for www | 1 | ns | Ingress host `store.lab` only | store.lab and www.store.lab answer from the store app |
| G08 | Large uploads fail with 413 | 2 | ns | Traefik `buffering` middleware `maxRequestBodyBytes` 1 MiB | a 10 MiB upload 200; the middleware still limits to 16-64 MiB |

## X - NetworkPolicy & CNI (10)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| X01 | After "zero trust" the client can't reach the backend | 1 | ns | default-deny (in + out) + client → backend allow, no DNS egress | client `/upstream` 200; default-deny unchanged; client can't reach 192.168.56.20:8080 |
| X02 | Frontend can't reach backend after the policy | 1 | ns | ingress `podSelector` label typo `frontned` | probes: app=frontend → backend open, app=reports blocked |
| X03 | Monitoring namespace blocked | 2 | ns | `namespaceSelector: team=monitoring`, namespace `monitoring` lacks the label | monitoring → metrics-api open, otherx blocked, policy unchanged |
| X04 | Policy allows port 80, still blocked | 2 | ns | policy `port: 80` (Service port), pod listens 8080 | web.portx.svc:80 open from the namespace; exactly one allowed port (8080/http) |
| X05 | Policy too permissive: everyone in `monitoring` can reach DB | 3 | ns | `namespaceSelector` and `podSelector` as two list items (OR) | only prometheus pod allowed (AND) |
| X06 | Egress to the external payment API blocked | 2 | ns | `ipBlock 192.168.56.0/24 except 192.168.56.16/28` (covers .20); the rest of the /24 open on every port | app=client → 192.168.56.20:8080 open, .20:22 and .31:22 blocked |
| X07 | New pods on one node have no network | 3 | cluster | calico-node DS `IP_AUTODETECTION_METHOD=first-found` + `updateStrategy: OnDelete`; only the `k8s-w3` pod restarted, so w3 registers the NAT `10.0.2.15` every VM shares | calico-node Ready everywhere, every node's Calico address on 192.168.56.0/24, matrix green |
| X08 | Pods stuck `ContainerCreating`: "failed to allocate IP" | 3 | cluster | Calico IPPool /26 with blockSize /29 exhausted | all pods Running (pool extended) |
| X09 | `shop` down after the "zero trust" rollout: DNS and the DB password never arrive | 2 | ns + cleanup.sh | `default-deny` (in+out) in `shop`, `default-deny-egress` in `external-secrets` | deny policies unchanged, shop e2e, ESO refresh, frontend→db and api→gw:22 blocked |
| X10 | Argo CD: every app `ComparisonError ... 192.168.56.20:3000: i/o timeout` | 2 | ns + cleanup.sh | Egress policy for the repo-server (selects `app.kubernetes.io/component: repo-server`) allows DNS only | lab-apps/demo/shop Synced after a hard refresh; an Egress policy still selects repo-server, none allows all egress |

## V - Storage (10)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| V01 | PVC `Pending` forever | 1 | ns | `storageClassName: fast-ssd` (doesn't exist) | Bound, pod Running |
| V02 | PVC `Pending`, "no persistent volumes available and no storage class is set" | 2 | ns | default-class annotation removed from local-path | Bound (default restored or class set) |
| V03 | Restored PV can't be reused | 2 | ns | PV `Released` with stale `claimRef`, Retain policy | new PVC Bound to that PV, data intact |
| V04 | Second replica `Pending`: "volume node affinity conflict" | 2 | ns | RWO local-path PVC shared by a 2-replica Deployment | 2 pods Ready on different nodes, each with its own local-path PVC (StatefulSet) |
| V05 | App: "permission denied" writing to its volume | 2 | ns | nfs-csi volume (root 755), pod runs as uid 1000 without fsGroup; namespace PSA `restricted` | 2 Ready sharing writes; still uid 1000, no root container; namespace still restricted |
| V06 | Can't grow StatefulSet disks: "updates to statefulset spec ... forbidden" | 3 | ns | change `volumeClaimTemplates` size | PVCs resized (expansion + `--cascade=orphan` recreate) |
| V07 | PVC resize rejected | 2 | ns | StorageClass `nfs-standard` (copy of nfs) with `allowVolumeExpansion: false` | same PVC/PV at 2Gi, data written before still there |
| V08 | PVC stuck `Terminating` | 1 | ns | `kubernetes.io/pvc-protection` while a pod still mounts it | PVC deleted, app migrated per ticket |
| V09 | Pod stuck `ContainerCreating`: "hostPath type check failed" | 1 | ns | `hostPath type: Directory` for missing dir | Running (DirectoryOrCreate) |
| V10 | Data lost after every pod restart | 1 | ns | data on `emptyDir` | data survives pod deletion (PVC) |

## A - Security (13)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| A01 | App logs `pods is forbidden: User "system:serviceaccount:..." cannot list` | 1 | ns | RoleBinding in wrong namespace | `kubectl auth can-i list pods --as=sa` yes, nothing broader |
| A02 | Dev can `get pods` but not `kubectl exec` | 2 | ns | Role lacks `pods/exec` (create) | exec works for dev user, no cluster-admin |
| A03 | In-cluster client gets 401 | 2 | ns | `automountServiceAccountToken: false` on SA | API call 200 |
| A04 | Deployment has 0 pods, `kubectl get pods` empty | 2 | ns | namespace PSA `enforce=restricted`, pod `privileged: true` and nothing restricted needs | 2 Ready; namespace still restricted |
| A05 | `CreateContainerConfigError`: "image will run as root" | 1 | ns | `runAsNonRoot: true`, image USER root | Ready, still non-root |
| A06 | App crashes: "Read-only file system" | 1 | ns | `readOnlyRootFilesystem: true`, app writes `/tmp` | Ready, rootfs still read-only |
| A07 | Security audit: everyone can read Secrets | 2 | ns | ClusterRole `secret-reader` bound to group `system:authenticated` "for the backup tool" | backup-agent can list Secrets cluster-wide; bob and default/default can't; no group grant left |
| A08 | New engineer's kubeconfig: "Unauthorized" | 2 | ns + cleanup.sh | alice's client cert signed by a self-made "team CA" (the API treats her as anonymous); task: issue via the CSR API with her key | whoami alice, `-n dev get pods` works; cert signed by the cluster CA with her original key; no kube-system access |
| A09 | Nothing can be created in namespace `shop`: "failed calling webhook" | 3 | ns | ValidatingWebhook `failurePolicy: Fail` -> service without endpoints | creates work (webhook fixed or scoped), webhook kept |
| A10 | All new pods crash after "security sidecar" rollout | 3 | ns | MutatingWebhook injects env that breaks app | pods Ready, webhook fixed/excluded per ticket |
| A11 | CI token suddenly rejected (401) | 2 | ns | the token was a TokenRequest **bound to a runner pod**, which is gone | the token in the file is ci2/ci-bot, can list pods in ci2, from a `service-account-token` Secret |
| A12 | Job `secret-sync` fails: `secrets "db-creds" is forbidden`, yet the app pod mounting the same Secret is fine | 2 | ns | Job runs `kubectl get secret db-creds` as SA `syncer`; Role grants `get` with `resourceNames: [db-cred]` (typo) | Job Complete; `can-i get secret/db-creds` yes, `get` other Secrets / `list secrets` no |
| A13 | Who read the `payments` API key yesterday? | 3 | cluster | audit policy logs Secrets at `Metadata`; setup reads `payments/api-key` as SA `ci/reporter` from a pod and as user `bob` | answer file names both identities + time + source; policy still `Metadata` for Secrets (no values in the log) |

## K - Control plane (17, all `cluster` unless noted)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| K01 | `kubectl`: "connection to the server ... was refused" | 2 | cluster | apiserver manifest `--etcd-servers=https://127.0.0.1:2397` | apiserver healthy, `kubectl get nodes` works |
| K02 | apiserver gone after "hardening" (3 mistakes, one in metadata) | 3 | cluster | `--enable-admission-plugins=...,PodSecurityPolicy`, `--tls-cert-file=.../apiserver.cert`, label value with a space (kubelet rejects the manifest); `--profiling=false` is valid | API up, mirror pod Ready, profiling off kept, valid plugins, cert files exist, 4 manifests |
| K03 | New pods stay `Pending`, no scheduler events | 2 | cluster | scheduler manifest image typo | test pod scheduled |
| K04 | Deployments don't create pods, scale does nothing | 2 | cluster | controller-manager `--kubeconfig` path wrong | RS reconcile works |
| K05 | Whole control plane down after disk move | 3 | cluster | etcd `--data-dir` changed, hostPath not updated | etcd healthy, **data preserved** (old objects still there) |
| K06 | Namespace `prod` deleted by mistake - restore it | 3 | cluster | setup takes etcd snapshot, then deletes ns | `prod` objects back from snapshot |
| K07 | Everything x509-expired after "a long weekend" | 3 | cluster | kubeadm-config `certificateValidityPeriod: 15m` (v1beta4); certs renewed with it and left to expire | `kubeadm certs check-expiration` all > 300 d, no short validity left in kubeadm-config, cluster healthy |
| K08 | Your kubectl stopped working, others' works | 1 | ns | dana's kubeconfig (a real CSR-issued cert): server port 6444, context user `dana@lab` (entry is `dana`), namespace `shp` | whoami dana, `get pods` lists shop, server 192.168.56.20:6443, TLS verified |
| K09 | apiserver crashloops after enabling audit logging | 2 | cluster | audit flags + the policy mounted, no hostPath for `/var/log/kubernetes/audit` | API + mirror pod Ready; audit flags kept; reading a Secret writes a fresh event to the node's audit.log; 4 manifests |
| K10 | scheduler "disappeared", no pod in kube-system | 2 | cluster | `--v=2` added with a **tab** for indentation: the kubelet can't parse the manifest | valid YAML, mirror pod Ready with `--v=2`, waiting pods Running, 4 manifests |
| K11 | Writes fail: "etcdserver: mvcc: database space exceeded" | 3 | cluster | etcd `--quota-backend-bytes=64Mi` + bulk ConfigMaps | alarm disarmed, compact + defrag, writes OK |
| K12 | CSRs stay `Pending` forever after approval | 3 | cluster | controller-manager missing `--cluster-signing-*` flags | approved CSR gets a certificate |
| K13 | Upgrade the cluster 1.36 → 1.37 (kubeadm) without app downtime | 3 | rebuild | `version: 1.36` (cluster rebuilt at 1.36; 1.37 debs cached on the nodes); labapp with a PDB under a probe | every node `v1.37.x` (control plane + kubelets), all uncordoned, probe saw no outage > 5 s |
| K14 | `kubectl` from the desktop fails; workers go NotReady one by one; fine on `k8s-cp1` | 2 | cluster | haproxy on `k8s-gw`: API backend → `192.168.56.22:6443` (reserved cp2, no VM) | desktop kubectl works; backend .21 (no .22), haproxy reports it UP; all nodes Ready |
| K15 | Rejoining `k8s-w3` fails with the wiki's join command | 2 | cluster | w3 drained, deleted, `kubeadm reset` (as T03); the command has an expired token (`--ttl 1s`, cleaned up) and the hash of another CA. w4 is not used (no VM) | w3 Ready, InternalIP .33, zone-b, logs work, kubelet enabled, no token without expiry |
| K16 | apiserver down after enabling encryption at rest | 3 | cluster | `--encryption-provider-config` added; aescbc key is 31 bytes and the file sits in a dir that isn't a hostPath mount | apiserver healthy; new **and** pre-existing Secrets stored `k8s:enc:aescbc:v1:` in etcd |
| K17 | `x509: certificate is valid for ..., not 192.168.56.20` from the desktops | 2 | cluster | certSANs dropped from kubeadm-config, the apiserver cert re-issued from it. kubeadm always adds the `controlPlaneEndpoint` host, so only the LB IP is lost: desktops fail, nodes don't | desktop kubectl works; the cert has DNS:k8s-api.lab + IP:192.168.56.20; kubeadm-config certSANs lists both; nodes Ready |

## L - Nodes & runtime (18, all `node`)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| L01 | `k8s-w2` `NotReady` | 1 | node | `systemctl stop kubelet` (and `disable`) on node | node Ready, kubelet enabled |
| L02 | Node NotReady: "container runtime is down" | 2 | node | containerd config: an appended `[plugins.'io.containerd.cri.v1.images'` header without `]` (and the table already exists) | containerd up, config loads, `max_concurrent_downloads = 10` kept, w1 Ready + runs pods |
| L03 | kubelet crashloops after config change | 2 | node | `evictionHard: {memory.available: 200MB}` (MB is not a quantity) in `/var/lib/kubelet/config.yaml` on w2 | Ready, tuning kept as 200Mi/200M + nodefs 10% |
| L04 | Node NotReady: "network plugin is not ready: cni config uninitialized" | 2 | node | `/etc/cni/net.d/*` removed on node | Ready, pods networked |
| L05 | Node NotReady after "control-plane IP change" | 2 | node | kubelet.conf server URL wrong port | Ready |
| L06 | `kubectl logs/exec` fail for pods on one node, pods run fine | 3 | node | `--node-ip` dropped from `kubeadm-flags.env` on `k8s-w2` + cloud-init's `127.0.1.1 k8s-w2` in `/etc/hosts` (loopback is skipped): InternalIP becomes the NAT `10.0.2.15` every VM shares | w2 InternalIP 192.168.56.32, logs/exec work on all nodes |
| L07 | Pods on one node `ContainerCreating`: sandbox image pull fails | 3 | node | containerd sandbox (pause) image -> unreachable registry | pods Running |
| L08 | Node flaps Ready/NotReady | 3 | node | `tc netem loss 30%` on node -> lease renewals fail | Ready stable 2 min |
| L09 | Images on one node never pull from the lab registry | 2 | node (w1) | w1's `certs.d/registry.lab:5000/hosts.toml` → port 5050; the image removed from w1's cache | edge-cache DaemonSet 3/3 Ready (w1 too); hosts.toml back to :5000; w1 pulls |
| L10 | A pod keeps coming back after every delete | 1 | node (w2) | static pod manifest `netdebug.yaml` (hostNetwork) left in w2's `/etc/kubernetes/manifests` | no netdebug pod for 60 s, no container left, `staticPodPath` unchanged, w2 Ready |
| L11 | `k8s-w3` unreachable; web moved, but `db-0` is stuck `Terminating` for 10 min | 3 | node | nft `lab_fault` on w3 drops cluster peers (desktop ssh kept); StatefulSet `db` on an NFS PVC runs there | `db-0` Ready on another node with its data and the same PVC; `web` Ready away from w3 |
| L12 | A node died and its pods took over an hour to move | 2 | node | Deployment tolerates `unreachable`/`not-ready` for 3600 s ("flap protection" copy-paste); setup partitions `k8s-w2` | `unreachable`/`not-ready` tolerations at most 120 s; 3 `api` replicas Ready away from w2 |
| L13 | Everything on `k8s-w1` is slow, probes time out; `kubectl top` shows little CPU | 3 | node | systemd drop-in `CPUQuota=20%` on `kubepods.slice` on w1 | `cpu.max` = max and no drop-in left (survives a reboot); `search` pods stable 60 s |
| L14 | `k8s-w2` NotReady after a routine reboot | 2 | node | swap file added to fstab, then `reboot`; kubelet `failSwapOn` | Ready, kubelet active, no swap active, no swap entry in `/etc/fstab` |
| L15 | Node audit after `k8s-w3`'s reboot: bridge sysctls missing | 1 | node (w3) | `br_netfilter` removed from modules-load.d, then a reboot | after the **test's reboot**: module loaded, bridge-nf-call-ip(6)tables + ip_forward = 1, w3 Ready |
| L16 | `k8s-w1` NotReady, kubelet logs `x509: ... not yet valid` | 2 | node (w1) | chrony stopped + disabled, `date -s "-400 days"` | chrony enabled + active, synced to .20 with offset < 1 s, w1 Ready, the kubelet's client cert unchanged |
| L17 | `k8s-w2` `DiskPressure`, pods evicted; `du` finds nothing big | 3 | node | `lab-logger` unit on w2 fills `/var` with a file it unlinks but keeps open | DiskPressure false, `/var` < 80%, unit stopped + disabled, pods Ready |
| L18 | Random new-connection timeouts from pods on `k8s-w3` only | 3 | node | `nf_conntrack_max=2048` via sysctl.d on w3 (re-set after kube-proxy start); load pod opens short connections | `nf_conntrack_max` ≥ 131072 and not lowered by sysctl.d, 2-min load with 0 conntrack drops |

## O - Cluster operations & API machinery (11; O12 moved to K13)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| O01 | Namespace stuck `Terminating` | 2 | ns + cleanup.sh | Backup CRs with finalizer `example.com/backup-cleanup`, the operator gone; the CRD stays (team-z still has a Backup) | old-team gone; CRD and team-z's Backup still there |
| O02 | Can't delete a custom resource | 2 | ns + cleanup.sh | Database CR with finalizer `example.com/drop-database`, no controller | orders-db gone; inventory-db and the CRD kept |
| O03 | `apply`: "no matches for kind PodDisruptionBudget in version policy/v1beta1" | 1 | ns | PDB policy/v1beta1 + Ingress networking.k8s.io/v1beta1 | PDB web policy/v1 (minAvailable 1); Ingress web routes legacy.lab (200) |
| O04 | `helm upgrade`: "another operation is in progress" | 2 | ns | `helm upgrade --wait` (broken image) killed halfway: revision left `pending-upgrade` | release deployed with today's values (Hallo, 1.4), 2 Ready, no pending revision |
| O05 | `helm install`: "exists and cannot be imported into the current release" | 2 | ns | Service `web` created by hand, without Helm's ownership metadata | release deployed; the **same** Service (UID) now owned by the release; 2 Ready behind it |
| O06 | Deleted the Deployment, pods still running | 1 | ns | `delete deployment --cascade=orphan` | no RS and no pod of oldapp; keeper still runs |
| O07 | Drain a worker with local data + DaemonSets + a bare pod | 2 | ns | on w2: emptyDir pod, DaemonSet pod, bare pod `scratch`; a plain drain refuses | w2's cache pod and scratch gone, w2 schedulable, cache 2 Ready, node-agent on all workers |
| O08 | Prod got dev settings | 2 | ns | prod overlay's patch has `target: {name: webapp}` (base is `web`): matches nothing, silently | the overlay renders 3 replicas + LOG_LEVEL=info; kust-prod/web 3 Ready with info; base unchanged |
| O09 | Who deleted the ConfigMap? | 3 | cluster | audit policy enabled; setup deletes as user `bob` | answer file names the user + time |
| O10 | `kubectl apply` conflict with field manager | 3 | ns | server-side apply conflict with another manager | change applied, ownership resolved |
| O11 | CRD upgrade broke `kubectl get` on old objects | 3 | ns | CRD `served: false` for the stored version | old objects readable/migrated |
| O12 | Upgrade the cluster one minor version (kubeadm) | - | - | moved to **K13** (real kubeadm upgrade on the VM cluster, reset `rebuild`) | see K13 |

## Q - Observability & forensics (5)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| Q01 | `kubectl logs` shows nothing, the app "logs a lot" | 1 | ns | `LOG_FILE=/var/log/labapp/app.log` (nothing on stdout); auditors want the file | a request the test sends shows up in `kubectl logs`; the file is still written |
| Q02 | Why did the pod restart at 03:00? | 1 | ns | 2-container pod; `report-builder` OOM-killed (limit 192Mi) | answers: container, reason OOMKilled, exit code 137, limit 192Mi |
| Q03 | Which pod is the noisy neighbour on `k8s-w1`? | 1 | ns | 5 tenants on w1, one (random) burns CPU (`INDEXER_WORKERS`) | answer names that pod (or its Deployment); all 5 still run |
| Q04 | Events already gone - reconstruct the incident | 2 | ns | 1.4 → 1.3 → 1.5 (exits); events deleted | answers: bad image 1.5, last good 1.3, SESSION_SECRET, exit code; nothing changed |
| Q05 | Find the failing request path in the logs of 6 pods | 2 | ns | 6 replicas, `ERROR_RATE` 0.3 on `GET /items`, a client calling a mix of paths | answers: `/items`, "pricing service timeout" |

## D - Delivery: Helm & Argo CD (12)

All apps come from the Gitea repo `lab/gitops` (charts `labapp`, `shop`; `envs/{dev,prod}`). "Fix in Git" = pushed
to `main` from `workspace/gitops`, not a live `kubectl` patch.

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| D01 | demo release "1.4 + Bonjour" never arrived | 2 | ns + gitops | commit to `envs/demo/values.yaml`: `image.tag: "1.4.0"` (doesn't exist) + `app.greting: Bonjour` (unknown key, silently ignored) | Synced/Healthy, rollout on an existing tag, `/` says Bonjour, fix in Git |
| D02 | Argo CD shows `labapp` OutOfSync: someone "hotfixed" prod | 2 | ns | `kubectl scale --replicas=1` + `kubectl set env FEATURE_X=on` on the live Deployment; auto-sync on, self-heal off | Synced; `FEATURE_X=on` now comes from Git (wanted per ticket), replicas = Git (3) |
| D03 | Auto-sync deployed a bad commit: Argo CD says Synced, demo is down | 2 | ns + gitops | commit to `main`: `labapp:2.0.0-rc1` (exits at start) + `strategy: Recreate` → 503 | demo 200, Synced + Healthy, no RC on `main` but the RC commit still in history (revert), auto-sync + selfHeal on |
| D04 | `payments` won't sync: "destination ... do not match any of the allowed destinations in project team-a" | 2 | ns + gitops | new AppProject `team-a` (destination typo `payment`) + app `payments` via Git | Synced/Healthy, still in `team-a`, explicit destinations (no `*`), sourceRepos unchanged |
| D05 | Every app `Unknown`: "repository not accessible: authentication required" | 1 | ns + gitops + openbao | Gitea user `argocd` gets a new password (published in OpenBao `secret/ci/gitea-argocd`); Argo CD's repo Secret `repo-gitops` keeps the old one; hard refresh | after a hard refresh lab-apps/demo/shop Synced + Healthy, no ComparisonError; the repo credentials are only `argocd` + the new password; Gitea rejects the old one |
| D06 | `demo` flips OutOfSync every minute, a 3rd pod comes and goes | 2 | ns + gitops | an HPA made by hand on demo (min 3); the chart renders `replicas: 2`; self-heal reverts the HPA | Synced with no sync operation for 120 s; one HPA (min >= 3) and the replicas follow it; Git doesn't render replicas (or ignoreDifferences + `RespectIgnoreDifferences=true`) |
| D07 | Every sync of demo + shop fails: "spec.selector ... field is immutable" | 2 | ns + gitops | chart commit moves `app.kubernetes.io/version` into `labapp.selectorLabels` (Deployment, Service, PDB) | demo + shop Synced/Healthy with the last sync Succeeded and answering; `main` renders a name + instance selector, pods keep the version label; no `Replace=true` |
| D08 | On-call ran `helm rollback`; it worked for a minute, then 1.5 was back | 2 | ns + gitops | `ledger` installed with helm, adopted by an Argo CD app (same release name); 1.5 (exits at start) via Git; `helm rollback --force-conflicts` undone by self-heal | ledger 200 + stable 30 s; Synced/Healthy with no sync for 60 s; `main` no 1.5; auto-sync prune + self-heal on; no `sh.helm.release.v1.ledger.*` Secrets |
| D09 | Sync stuck `Running`: "waiting for completion of hook batch/Job/billing-migrate" | 2 | ns + gitops | new app `billing`: the migration Job is a helm `pre-install,pre-upgrade` hook (= PreSync) reading Secret `db-creds`, which the chart's SealedSecret creates in the Sync phase | last sync Succeeded with the PreSync migration Succeeded; a fresh sync (the test starts one) too; `db-creds` owned by its SealedSecret; pods Ready |
| D10 | `web-prod` runs 1 pod with debug logs, like dev | 2 | ns + gitops | `apps/web-prod.yaml` `valueFiles: [envs/web-prod, envs/web-dev]` ("shared defaults"; the last file wins) | web-prod 3 Ready + `LOG_LEVEL=info`, web-dev 1 + `debug`, both Synced; both values files unchanged |
| D11 | New `metrics` app merged a day ago - Argo CD doesn't know it exists | 2 | ns + gitops | child Application committed as `apps/team/metrics.yaml`; the root `lab-apps` (bootstrapped by hand from `bootstrap/root.yaml`) has no `directory.recurse` | `metrics` Application Synced/Healthy with pods; `lab-apps` Synced/Healthy; the file still under `apps/team/` (the reset puts the root's spec back) |
| D12 | After a cleanup commit the database came back empty | 3 | ns | auto-sync `prune: true`; commit drops the PVC from the chart; pruned on the next rollout; PV `Released` (Retain) | same PV re-bound, data intact, PVC back in Git with `Prune=false`, app Synced |

## Y - Secrets (10)

| ID | Ticket | Lvl | Reset | Emulation | Verify |
|---|---|---|---|---|---|
| Y01 | demo: rotated token rejected (401), the old one still works | 2 | ns + gitops | the new token sealed (strict) for `demo-staging` (where it decrypts) and committed for demo: "no key could decrypt secret", the old Secret stays | new token 200, old 401, SealedSecret Synced, sealed in Git |
| Y02 | After the cluster rebuild every SealedSecret fails to decrypt | 3 | cluster | sealing key Secrets deleted + controller restarted (new key generated); backup in `.state/sealed-secrets-key.yaml` | old key restored + controller restarted, all SealedSecrets Synced, Git untouched (no reseal) |
| Y03 | shop down: ExternalSecret SecretSyncedError after a "path cleanup" | 2 | ns + gitops + openbao | `secret.externalSecret.remoteKey: shop/app` (kv is at `secret/shop`); setup deletes `shop-secrets` and the pods | ExternalSecret Ready, 3 keys, shop e2e, fix in Git, nothing copied in OpenBao |
| Y04 | `prod` API can't start: SecretStore "permission denied" | 2 | ns + openbao | namespaced SecretStore `prod/openbao` logs in as SA `eso-reader` (role `prod`); the role is bound to SA `default` | store + ExternalSecret Ready with `secret/prod/app`'s api_key; `api` Ready; role bound to exactly `prod/eso-reader` with only `prod-read`; store still uses `eso-reader` |
| Y05 | ClusterSecretStore not Ready: "x509: certificate signed by unknown authority" | 2 | ns + cleanup.sh | `external-secrets/lab-ca` (the store's caProvider) replaced by an older CA with the **same subject** | `lab-ca` = the current CA (fingerprint); store Ready over https with the same caProvider; `shop-secrets` refreshed after a forced sync; shop e2e |
| Y06 | All ExternalSecrets failing since gateway maintenance | 1 | ns | `systemctl restart openbao` on `k8s-gw`: it comes back sealed | OpenBao unsealed, ExternalSecrets Ready after a forced refresh |
| Y07 | Rotated the API token in OpenBao; notifier still sends the old one (401) | 2 | ns + openbao | `notify`: ESO syncs `secret/notify/api` to Secret `api-token` (15 s); `upstream` reads it as a mounted file, `notifier` via `env.secretKeyRef`; setup rotates | notifier `/upstream` 200; the test rotates **again** and notifier keeps working without a restart; the token still comes from the Secret |
| Y08 | Secret `api-key` flips between two values every minute | 3 | ns | legacy and new ExternalSecret both target `api-key` with `creationPolicy: Merge` | one ExternalSecret owns `api-key` (`Owner`), value stable 3 min, legacy one gone from Git |
| Y09 | New teammate can't decrypt `secrets/prod.enc.yaml`: sops finds no key | 2 | ns + gitops | the file is encrypted for the team key; a later commit adds alice's age recipient to `.sops.yaml`; nobody runs `sops updatekeys` | at `main` the file decrypts with alice's and the team key, content unchanged, still encrypted; alice still in `.sops.yaml` |
| Y10 | Security scan: plaintext password in Git (`secrets/new-service.enc.yaml`) | 2 | ns + gitops | `.sops.yaml` changed to `encrypted_regex: ^data$`; the file uses `stringData`, so it has sops metadata but plaintext values; the password is live in `newsvc`'s Redis | every value `ENC[...]`; the rule covers data + stringData; a new password in the file; Redis accepts it and rejects the leaked one |

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
