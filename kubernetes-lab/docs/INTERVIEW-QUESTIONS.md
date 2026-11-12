# Kubernetes interview question bank (~210)

Each question has the **key points** a strong answer covers. Lab scenario IDs in brackets
show where you can practise it hands-on (see CATALOG.md). Levels: (J) junior, (M) mid, (S) senior/SRE.

---

## 1. Architecture & fundamentals

1. **Walk me through what happens when you run `kubectl apply -f deploy.yaml`.** (M) - kubectl -> apiserver (authn, authz, admission mutating -> schema -> validating) -> etcd; Deployment controller creates RS, RS creates Pods; scheduler binds; kubelet pulls, CRI creates sandbox (pause) + CNI, containers start; endpoints updated. [K03, K04]
2. **Control-plane components and what each does.** (J) - apiserver (only etcd client), etcd (state), scheduler (binding), controller-manager (reconcile loops), cloud-controller-manager; node: kubelet, kube-proxy, runtime.
3. **What is a static pod and how do you find/modify one?** (M) - kubelet watches `staticPodPath` (`/etc/kubernetes/manifests`), mirror pod in API, edit the file not the object. [K01, K10, L10]
4. **How does etcd achieve consistency? Why an odd number of members?** (S) - Raft, quorum = n/2+1, 3 tolerates 1 failure, 5 tolerates 2; even numbers add no tolerance.
5. **What happens if etcd is lost / apiserver is down - do running pods stop?** (M) - no; kubelets keep running containers, no changes/reconciliation, Services keep working (kube-proxy rules stay).
6. **Declarative vs imperative; what is reconciliation?** (J) - desired vs observed state, controllers loop, level-triggered.
7. **Explain `resourceVersion`, optimistic concurrency and watches.** (S) - conflicts (409), informers, list+watch, bookmarks.
8. **Labels vs annotations vs selectors.** (J) - identifying vs non-identifying metadata; set-based selectors.
9. **What are namespaces good for - and what are they NOT?** (J) - scoping names, RBAC, quotas, policies; not a security boundary by themselves; cluster-scoped objects.
10. **Owner references and garbage collection; cascading delete modes.** (M) - foreground/background/orphan. [O06]
11. **Finalizers: what are they, why do objects get stuck?** (M) - pre-delete hooks; controller gone -> stuck Terminating; remove only after understanding. [O01, O02, P13]
12. **CRDs and operators - how do they work?** (M) - schema, versions, conversion, controller watching CRs. [O11]
13. **Admission controllers: mutating vs validating, webhooks, failurePolicy.** (S) - order, timeouts, `failurePolicy: Fail` can block the cluster; namespaceSelector to exclude kube-system. [A09, A10]
14. **API deprecations: how do you find manifests using removed APIs before an upgrade?** (M) - `kubectl convert`, pluto/kubent, apiserver deprecation warnings, audit. [O03]
15. **Server-side apply vs client-side apply.** (S) - field managers, conflicts, `--force-conflicts`. [O10]

## 2. Pods, containers & lifecycle

16. **Pod phases vs container states vs conditions.** (J) - Pending/Running/Succeeded/Failed/Unknown; Waiting/Running/Terminated; PodScheduled, Initialized, ContainersReady, Ready.
17. **A pod is in `CrashLoopBackOff`. Your steps?** (J) - `describe` (events, exit code, lastState), `logs --previous`, command/args/env, probes, OOM, dependencies; backoff 10s->5min. [P04, P05]
18. **Exit codes 0, 1, 126, 127, 137, 139, 143 - what do they mean?** (M) - 128+signal; 137 SIGKILL (OOM or kill), 143 SIGTERM, 139 SIGSEGV, 127 not found. [P07, P08]
19. **`ImagePullBackOff` vs `ErrImagePull`; causes.** (J) - tag/name typo, auth, rate limits, network/DNS, arch; check events + `crictl pull` on node. [P01, P02, P03]
20. **`CreateContainerConfigError` vs `CreateContainerError` vs `RunContainerError`.** (M) - missing CM/Secret/key vs runtime create failure vs exec failure. [P06, P07, C05]
21. **Liveness vs readiness vs startup probes - and the classic mistakes.** (M) - liveness restarts, readiness removes from endpoints, startup protects slow starts; don't check dependencies in liveness. [P09, P10, P11]
22. **Init containers vs sidecars; native sidecars (`restartPolicy: Always`).** (M) - ordering, Jobs with sidecars. [P12, P14]
23. **Pod termination sequence.** (S) - deletionTimestamp -> endpoints removed (in parallel!) -> preStop -> SIGTERM -> grace -> SIGKILL; why preStop sleep. [P16]
24. **Pod stuck Terminating - causes and safe fixes.** (M) - finalizers, node down, runtime issues; `--grace-period=0 --force` consequences. [P13]
25. **restartPolicy options and which controllers allow which.** (J) - Always (Deployments), OnFailure/Never (Jobs).
26. **What is the pause container?** (M) - holds namespaces (net/IPC), PID 1 of the sandbox.
27. **How do you debug a distroless container?** (M) - `kubectl debug -it --image=busybox --target=app`, ephemeral containers, node debug.
28. **QoS classes and eviction order.** (M) - Guaranteed/Burstable/BestEffort; eviction ranking by usage over requests. [R04]
29. **Requests vs limits for CPU and memory; what happens when exceeded?** (J) - CPU throttled (CFS), memory OOM-killed; scheduling uses requests. [P08, R03]
30. **Ephemeral storage limits and evictions.** (M) - emptyDir, logs, writable layer; `ephemeral-storage` requests/limits. [P15]

## 3. Configuration & secrets

31. **ConfigMap vs Secret; are Secrets encrypted?** (J) - base64 only; enable encryption at rest (EncryptionConfiguration, KMS); RBAC on secrets. [A07, K16]
32. **Why didn't my app pick up the ConfigMap change?** (J) - env vars fixed at start; volume updates eventually; `subPath` never updates; checksum annotation pattern. [C01, C02]
33. **Immutable ConfigMaps/Secrets - why use them?** (M) - performance (no watches), safety; rotate via new name. [C06]
34. **How do you get Secrets into the cluster safely (GitOps)?** (S) - Sealed Secrets, SOPS, External Secrets Operator, CSI secrets store, Vault/OpenBao (details in section 17). [Y01, Y03, Y09]
35. **Downward API - what can you expose?** (M) - pod name/ns/IP/labels/annotations, resource limits. [C08]
36. **Common base64/newline pitfalls with Secrets.** (M) - `echo -n`, `--from-file` newlines, `stringData`. [C03, C07]

## 4. Scheduling

37. **Pod is `Pending`. How do you troubleshoot?** (J) - events "0/4 nodes are available: ...", resources, selectors/affinity, taints, PVC binding, quotas, scheduler health. [S01-S14]
38. **nodeSelector vs node affinity vs pod affinity/anti-affinity.** (M) - required vs preferred; topologyKey. [S02, S04, S13]
39. **Taints and tolerations; NoSchedule vs PreferNoSchedule vs NoExecute.** (J) - built-in taints (not-ready, unreachable, disk-pressure), tolerationSeconds. [S03, W06]
40. **Topology spread constraints; why Pending with free capacity?** (S) - maxSkew, whenUnsatisfiable, node/zone labels, minDomains. [S05]
41. **Priority and preemption; PodDisruptionBudgets interplay.** (S) - preemptionPolicy Never, system-cluster-critical. [S10]
42. **How does the scheduler score nodes?** (S) - filter (predicates) then score (plugins: LeastAllocated, ImageLocality, ...), scheduling framework, profiles.
43. **What does cordon / drain / uncordon do exactly?** (J) - unschedulable flag; eviction API respecting PDBs; DaemonSets, emptyDir flags. [S06, W12, O07]
44. **Multiple schedulers / `schedulerName`.** (M) - custom profiles; pods silently Pending if scheduler missing. [S07]
45. **What happens to pods when a node dies?** (M) - node NotReady -> taint `unreachable` -> eviction after tolerationSeconds (300 s default) -> Deployment pods recreated; StatefulSet pods NOT until node confirmed gone (at-most-one semantics). [L01, L11, L12]

## 5. Workload controllers

46. **Deployment vs StatefulSet vs DaemonSet vs Job vs CronJob - when which?** (J)
47. **How does a rolling update work? maxSurge / maxUnavailable?** (J) - new RS scaled up, old down, readiness gates progress. [W01]
48. **Rollback: how, and what limits it?** (J) - `rollout undo`, revisionHistoryLimit. [W11]
49. **Rollout stuck - how do you detect and fix?** (M) - progressDeadlineSeconds, `ProgressDeadlineExceeded`, readiness failures. [W01]
50. **Why is `spec.selector` immutable and what happens if labels overlap?** (M) - controllers fight/adopt; Services selecting multiple apps. [W02, W03]
51. **StatefulSet guarantees: identity, ordering, storage.** (M) - ordinal names, headless Service DNS, volumeClaimTemplates, OrderedReady vs Parallel. [W04, W05, V06]
52. **Updating a StatefulSet's volumeClaimTemplates.** (S) - immutable; resize PVCs, delete STS with `--cascade=orphan`, recreate. [V06]
53. **Job semantics: completions, parallelism, backoffLimit, activeDeadlineSeconds, ttlSecondsAfterFinished, podFailurePolicy.** (M) [W07]
54. **CronJob didn't run - checklist.** (M) - suspend, concurrencyPolicy, startingDeadlineSeconds, timeZone, missed schedules > 100. [W08]
55. **Pause/resume rollouts - use cases.** (J) [W09]
56. **HPA and manual scaling conflicts; GitOps and replicas.** (M) - omit replicas from manifests when HPA is used. [W10]
57. **Blue/green and canary with plain Kubernetes.** (M) - two Deployments + Service selector switch, weighted routes with Gateway API.

## 6. Services, networking & DNS

58. **Service types: ClusterIP, NodePort, LoadBalancer, ExternalName, headless.** (J) [N09, N13]
59. **How does a ClusterIP actually work?** (M) - virtual IP, kube-proxy iptables/IPVS/nftables DNAT to endpoints, conntrack; EndpointSlices.
60. **Service has no endpoints - why?** (J) - selector mismatch, pods not Ready, wrong namespace. [N01, P10]
61. **port vs targetPort vs nodePort vs containerPort; named ports.** (J) [N02, N03]
62. **`externalTrafficPolicy: Local` vs `Cluster`; source IP preservation.** (M) - health-check node port, imbalance. [N04]
63. **Kubernetes networking model requirements.** (M) - every pod gets an IP, pod-to-pod without NAT, CNI implements it.
64. **What does a CNI plugin do; overlay vs routed (VXLAN, IPIP, BGP, eBPF).** (S) [N12, X07]
65. **Pod-to-pod works on the same node but not across nodes.** (S) - overlay ports blocked (VXLAN 4789, IPIP proto 4, BGP 179), MTU, routes, CNI agent down. [N12]
66. **How does DNS work in a pod? Explain `ndots:5`.** (M) - `/etc/resolv.conf` -> CoreDNS ClusterIP, search domains, names with < 5 dots tried with suffixes first; trailing dot. [N08]
67. **Service DNS names: svc, svc.ns, FQDN, pod records, SRV.** (J) [N05, W05]
68. **CoreDNS crashing / loops / slow - how to debug?** (M) - Corefile, `loop` plugin, forward upstream, logs, metrics, NodeLocal DNSCache. [N06, N07]
69. **Intermittent 5-second DNS delays - known cause?** (S) - conntrack race with parallel A/AAAA over one UDP socket (glibc/musl); `single-request-reopen`, NodeLocal DNS, TCP.
70. **kube-proxy modes and when one node can't reach Services.** (S) [N11]
71. **How would you test connectivity from inside the cluster?** (J) - netshoot/curl pod, `kubectl debug`, port-forward, nslookup, `nc -zv`.
72. **What is an EndpointSlice; selector-less Services for external DBs.** (M) [N10]
73. **Why can't I reach my app through the Service but port-forward works?** (M) - app bound to 127.0.0.1, readiness, NetworkPolicy. [N14]
74. **MTU problems in Kubernetes networks.** (S) - overlay overhead, large responses hang, PMTUD black holes.

## 7. Ingress & Gateway API

75. **Ingress vs Gateway API - why the move?** (M) - role separation (GatewayClass/Gateway/Routes), portable features, cross-namespace with ReferenceGrant; ingress-nginx retirement.
76. **Ingress returns 404 / 503 - how to triage?** (J) - ingressClassName, host/path match, backend service/port, endpoints, controller logs. [G01, G02, G07]
77. **pathType Prefix vs Exact vs ImplementationSpecific; rewrites.** (M) [G03]
78. **TLS termination: where does the cert come from? cert-manager flow.** (M) - Secret in same namespace, Issuer/Certificate, ACME HTTP-01/DNS-01. [G04]
79. **HTTPRoute not attached - which statuses do you read?** (M) - `Accepted`, `ResolvedRefs`, listener `allowedRoutes`, ReferenceGrant. [G05, G06]
80. **How do you expose a service in a bare-metal cluster?** (M) - NodePort, MetalLB, hostNetwork ingress, kube-vip.

## 8. NetworkPolicy

81. **What is the default if no NetworkPolicy exists? What does "isolated" mean?** (J) - allow-all; a pod becomes isolated per direction once selected by any policy.
82. **Write a default-deny with DNS allowed.** (M) - egress to kube-system/kube-dns UDP+TCP 53. [X01]
83. **AND vs OR in `from:` items.** (S) - same item = AND, separate items = OR. [X05]
84. **Policy ports: service port or container port?** (M) - pod (container) port, after DNAT. [X04]
85. **namespaceSelector by name.** (M) - `kubernetes.io/metadata.name` label. [X03]
86. **Does the CNI matter for NetworkPolicy?** (J) - enforcement needs a policy-capable CNI (Calico, Cilium); Flannel alone doesn't.
87. **Egress to external IPs/FQDNs.** (M) - ipBlock/except; FQDN policies are CNI-specific. [X06]

## 9. Storage

88. **PV vs PVC vs StorageClass; static vs dynamic provisioning.** (J) [V01, V02]
89. **PVC `Pending` - checklist.** (J) - class exists/default, provisioner running, WaitForFirstConsumer, capacity, access modes, topology. [V01, V02, V04]
90. **Access modes RWO, ROX, RWX, RWOP - and Multi-Attach errors.** (M) [V04]
91. **Reclaim policies; reusing a Released PV.** (M) - Retain/Delete, clear `claimRef`. [V03]
92. **volumeBindingMode WaitForFirstConsumer - why?** (M) - topology-aware provisioning.
93. **Permission denied on volumes: fsGroup, fsGroupChangePolicy, runAsUser.** (M) [V05]
94. **Volume expansion: requirements and steps.** (M) - `allowVolumeExpansion`, CSI support, online/offline. [V07, V06]
95. **Why is my PVC stuck Terminating?** (J) - pvc-protection finalizer while in use. [V08]
96. **CSI: what are the components?** (S) - controller (provisioner, attacher, resizer, snapshotter sidecars), node plugin, VolumeAttachment.
97. **emptyDir vs hostPath vs PVC - risks of hostPath.** (J) [V09, V10]
98. **Backups of stateful apps in Kubernetes.** (S) - VolumeSnapshots, Velero, app-consistent dumps, etcd isn't your data backup.

## 10. Security

99. **AuthN vs AuthZ vs admission in the apiserver.** (M)
100. **RBAC: Role/ClusterRole/RoleBinding/ClusterRoleBinding - combinations.** (J) - ClusterRole + RoleBinding = namespaced grant. [A01]
101. **How do you check what a user/SA can do?** (J) - `kubectl auth can-i --as`, `--list`, `who-can`/`rbac-tool`. [A01, A07]
102. **Subresources in RBAC (pods/exec, pods/log, deployments/scale).** (M) [A02]
103. **ServiceAccounts and tokens: bound (projected) vs legacy secrets; automount.** (M) [A03, A11]
104. **Pod Security Admission levels and modes.** (M) - privileged/baseline/restricted, enforce/audit/warn; pods rejected = RS events. [A04]
105. **securityContext essentials.** (J) - runAsNonRoot, runAsUser, readOnlyRootFilesystem, allowPrivilegeEscalation, capabilities drop ALL, seccomp RuntimeDefault. [A05, A06]
106. **How do users authenticate? Issuing a user certificate via the CSR API.** (M) - client certs, OIDC, tokens; CSR approve + signerName. [A08, K12]
107. **A webhook broke the cluster - what now?** (S) - failurePolicy, timeoutSeconds, namespaceSelector, delete/patch the webhook config. [A09]
108. **Secrets hygiene: encryption at rest, RBAC, audit, rotation.** (S) [K16, A13, Y07]
109. **Image security: signing, scanning, admission policy (Kyverno/Gatekeeper), pull secrets.** (M) [P02]
110. **What is the attack path from `pods/exec` or `create pods` to cluster-admin?** (S) - privileged pods, hostPath, SA token theft; why these verbs are sensitive.

## 11. Control plane & cluster operations

111. **`kubectl` says "connection refused" - where do you look?** (M) - kubeconfig/context, apiserver static pod (`crictl ps -a`, `crictl logs`), manifest, certs, etcd. [K01, K08]
112. **How do you debug a crashing apiserver when kubectl doesn't work?** (S) - node shell, `crictl`, `/var/log/pods`, `journalctl -u kubelet`, manifest backup/diff. [K01, K02, K09]
113. **Scheduler or controller-manager down - symptoms?** (M) - Pending without events vs no RS reconciliation. [K03, K04]
114. **etcd backup & restore procedure.** (S) - `etcdctl snapshot save` with certs, `etcdutl snapshot restore` to new data-dir, point static pod at it. [K06]
115. **etcd "database space exceeded".** (S) - quota, compaction, defrag, alarm disarm, event TTL/object churn. [K11]
116. **Certificate expiry in kubeadm clusters.** (S) - 1 year default, `kubeadm certs check-expiration/renew`, kubelet client rotation, restart static pods. [K07]
117. **kubeadm upgrade sequence.** (S) - control plane first (one minor at a time), drain, kubeadm upgrade apply/node, kubelet+kubectl, uncordon; version skew policy. [K13]
118. **Version skew rules.** (M) - kubelet may be up to 3 minors older than apiserver, never newer; kubectl +/-1.
119. **High availability control plane - what matters?** (S) - stacked vs external etcd, LB in front of apiservers, quorum.
120. **Namespace stuck Terminating.** (M) - finalizers on remaining objects / unavailable APIServices; never blindly patch the namespace. [O01]
121. **ResourceQuota and LimitRange interplay.** (M) - quota requiring requests, LimitRange defaults/min/max. [R05, R10]
122. **Helm: release stuck, upgrade failures, ownership.** (M) - `helm history`, rollback, release secrets, meta.helm.sh annotations. [O04, O05, D08]
123. **Kustomize bases/overlays/patches; when vs Helm.** (M) [O08]
124. **Auditing: who changed/deleted something?** (S) - audit policy levels, log backend, events retention. [O09]

## 12. Nodes, kubelet & runtime

125. **Node `NotReady` - troubleshooting steps.** (J) - `describe node` conditions, kubelet status/logs, runtime, CNI, disk/memory pressure, certs, network to apiserver. [L01-L05]
126. **What is the CRI? Docker vs containerd vs CRI-O; `crictl` vs `docker`.** (M)
127. **Kubelet configuration: where it lives, how to change safely.** (M) - `/var/lib/kubelet/config.yaml`, flags env file, drop-ins, restart. [L03, S12]
128. **cgroup drivers and why they must match.** (M) - systemd vs cgroupfs. [L03]
129. **Node pressure evictions vs API-initiated evictions.** (M) - thresholds, soft/hard, grace periods, taints. [R04, R08]
130. **Image garbage collection and disk usage on nodes.** (M) - imageGCHigh/LowThresholdPercent, `crictl rmi --prune`. [R08]
131. **`kubectl logs`/`exec` fail but pods run - why?** (S) - apiserver -> kubelet connectivity, node InternalIP, kubelet serving certs, firewall 10250. [L06]
132. **Swap and Kubernetes.** (M) - historically unsupported; NodeSwap feature, failSwapOn. [L14]
133. **Where are container logs on a node?** (J) - `/var/log/pods`, `/var/log/containers`, rotation by kubelet.
134. **What happens to node-local data when a node is replaced?** (M) - local PVs bound to node, StatefulSets stuck.

## 13. Resources, autoscaling & performance

135. **HPA shows `<unknown>` - why?** (J) - metrics-server missing/broken, no requests, wrong metric. [R01, R02]
136. **How does HPA compute desired replicas? behavior/stabilization.** (M) - ceil(current * actual/target), tolerance 10%, scaleDown stabilization 300 s. [R09]
137. **VPA vs HPA vs Cluster Autoscaler vs Karpenter.** (M)
138. **CPU limits: to set or not to set? CFS throttling.** (S) - throttling at low average usage, `cpu.stat nr_throttled`; many teams drop CPU limits, keep requests. [R03]
139. **Memory limits and JVM/Go/Node runtimes.** (S) - container-aware heaps, GOMEMLIMIT, MaxRAMPercentage. [P08]
140. **Right-sizing requests: over-requesting vs bin packing.** (M) [R06]
141. **PID limits and fork failures.** (S) [R07]
142. **How do you find a noisy neighbour?** (J) - `kubectl top pods --sort-by`, node `crictl stats`, cgroup files. [Q03]

## 14. Observability & debugging practice

143. **Your first five commands when an app is down.** (J) - get pods -o wide, describe, logs (--previous), get events --sort-by, get endpoints/svc.
144. **Events: retention and how to reconstruct after they're gone.** (M) - 1 h TTL default, lastState, RS history, logs, monitoring. [Q04]
145. **Logs from many pods at once.** (J) - `kubectl logs -l app=x --prefix`, stern. [Q05]
146. **App logs to a file, not stdout - problem and fix.** (J) [Q01]
147. **Metrics stack basics: metrics-server vs Prometheus/kube-state-metrics.** (M)
148. **Ephemeral debug containers and node debugging (`kubectl debug node/...`).** (M)
149. **How do you load test and watch a rollout safely?** (M) [P16]

## 15. Scenario / design questions (open-ended)

150. **Deploys cause a burst of 502s - why and how to fix?** (S) - endpoint removal race, preStop, readiness, graceful shutdown, maxUnavailable. [P16]
151. **Cluster DNS is slow at peak - what do you check?** (S) - CoreDNS CPU/replicas, ndots, cache, NodeLocal DNS, conntrack. [N08]
152. **A node died at night: walk through what Kubernetes did and what you check in the morning.** (S) [L01, L11]
153. **etcd is slow - effects and diagnosis.** (S) - fsync latency (disk), large objects, too many events, compaction; apiserver latency spikes.
154. **You upgraded the cluster and some manifests fail - why?** (M) - removed APIs, PSP removal, feature gates. [O03]
155. **Design multi-tenant namespaces for 10 teams.** (S) - RBAC, quotas, LimitRanges, PSA, NetworkPolicy default deny, separate node pools, policy engine. [B03]
156. **How do you roll out a breaking config change with zero downtime?** (M) - versioned ConfigMaps, rolling update, readiness.
157. **Stateful app on Kubernetes - what can go wrong?** (S) - storage topology, failover, StatefulSet + node failure semantics, backups. [B04]
158. **How would you troubleshoot intermittent timeouts between two services?** (S) - which pods/nodes, conntrack, MTU, NetworkPolicy, DNS, retries/timeouts, tcpdump in netns.
159. **Explain a production incident you handled - structure.** (all) - detect, mitigate, root cause, follow-ups; blameless postmortem.
160. **How do you prevent "works in staging, breaks in prod"?** (M) - same manifests via overlays, policy checks in CI, image digests, admission policies. [B05]

## 16. Helm & GitOps (Argo CD)

161. **Helm rollback vs Argo CD rollback vs `git revert` - which one when?** (M) - `helm rollback` re-applies a stored release revision (release Secrets); Argo CD renders with `helm template` and keeps no Helm release, so with self-heal a live rollback is undone within seconds; Argo CD's own rollback needs auto-sync off; in GitOps the durable fix is `git revert`, so Git stays the truth. [D03, D08]
162. **What is drift, and what do auto-sync and self-heal each do about it?** (M) - live ≠ Git = OutOfSync; auto-sync applies new Git revisions; self-heal also re-applies when the live state changes; manual hotfixes vanish or linger as OutOfSync; first decide whether Git or live is right, then commit or sync. [D02]
163. **Sync status vs health status.** (J) - Synced = live matches Git; Healthy = the resources actually work (rollout progressing, pods Ready); Synced + Degraded is normal after a bad image; sync itself fails only on apply errors (schema, immutable field, RBAC, project policy). [D03, D07]
164. **An app stays OutOfSync forever though nobody touches it. Why?** (M) - fields changed by controllers, webhooks or defaulting: HPA-owned `replicas`, injected sidecars, CRD defaults; fix: drop the field from Git, or `ignoreDifferences` + `RespectIgnoreDifferences=true`, server-side diff. [D06]
165. **What does an AppProject restrict?** (M) - source repos, destinations (cluster + namespace), cluster/namespaced resource allow/deny lists, project roles, sync windows; "not permitted in project" is Argo CD policy, `Forbidden` is the controller's Kubernetes RBAC; grant the minimum, never `*`. [D04]
166. **Argo CD can't reach the Git repo - triage.** (J) - repo connection state, repo Secret labelled `argocd.argoproj.io/secret-type: repository`, credentials/TLS/known_hosts, repo-server logs, NetworkPolicy egress from repo-server, DNS. [D05, X10]
167. **Prune: what does it delete, and how do you protect stateful resources?** (S) - resources tracked by the app but gone from Git; a PVC with `Delete` reclaim takes the data with it; `Prune=false` / `Delete=false` sync-option annotations, `helm.sh/resource-policy: keep` for plain Helm, `Retain` reclaim policy, backups. [D12]
168. **Sync phases, waves and hooks: in what order do things apply, and why does a hook hang?** (M) - PreSync → Sync → PostSync (SyncFail on error), lower wave first inside a phase; hooks must complete or be healthy; a hook that needs a resource from a later phase waits forever; `hook-delete-policy: BeforeHookCreation`. [D09]
169. **Helm values precedence; "my value is ignored" - how do you debug it?** (J) - chart `values.yaml` < parent chart values < `-f` files left to right (last wins) < `--set`; key typos are silently ignored; `helm template --debug`, `helm get values`, `values.schema.json`. [D01, D10]
170. **Why must a chart's selector labels never include the version?** (M) - `spec.selector` is immutable; a version label in the selector breaks every upgrade; keep selectors to stable `app.kubernetes.io/name` + `instance`. [D07, W02]
171. **App of apps vs ApplicationSet.** (M) - a root app renders child Application manifests from a path (directory recursion, children must live in the Argo CD namespace); ApplicationSet generators (git, list, cluster, matrix) template many apps; bootstrap and blast radius. [D11]
172. **What should Argo CD manage, and what should it not?** (S) - apps vs cluster addons; bootstrap order (CNI, CSI, CRDs, Argo CD itself); self-heal fighting operators or break-glass fixes; cluster-scoped resources and project boundaries.
173. **GitOps DR: the cluster is rebuilt from scratch. What do you need besides Git?** (S) - Argo CD install + repo credentials, the Sealed Secrets key, a reachable and unsealed secret backend with its auth config, CRD ordering, PV data backups; rehearse it. [B07, Y02]

## 17. Secrets management

174. **Sealed Secrets: how does it work, and what are the scopes?** (M) - the controller holds the private key; `kubeseal` encrypts with the public cert; strict (name + namespace), namespace-wide, cluster-wide; renaming or moving a strict secret means resealing. [Y01]
175. **The Sealed Secrets controller key is gone. What happens, and how do you prevent it?** (S) - the controller generates a new key and existing SealedSecrets no longer decrypt; back up the key Secrets (label `sealedsecrets.bitnami.com/sealed-secrets-key`), restore them and restart the controller; key renewal (30 d) keeps old keys for decryption. [Y02]
176. **ESO vs Vault Agent Injector vs Secrets Store CSI vs SOPS - when which?** (S) - ESO syncs backend values into native Secrets (GitOps-friendly, the value lands in etcd); the injector renders files into the pod through a sidecar (no Secret object, tied to Vault); CSI mounts at pod start (optional sync); SOPS encrypts in Git and decrypts at deploy time, no runtime backend; trade-offs: rotation, etcd exposure, backend as a runtime dependency. [Y03, Y09]
177. **An ExternalSecret isn't syncing - triage path.** (M) - ExternalSecret conditions/events, SecretStore Ready, provider auth (role ↔ SA + namespace), remote path, TLS (`caProvider`), egress to the backend, ESO controller logs; never print values. [Y03, Y04, Y05, X09]
178. **How does Kubernetes auth in Vault/OpenBao work?** (S) - the client presents its SA JWT; Vault validates it (TokenReview or JWKS); a role binds SA names + namespaces (and audience) to policies and returns a short-lived token; wrong SA or namespace = `permission denied`. [Y04]
179. **Vault/OpenBao is sealed. What does that mean for the cluster?** (M) - the storage key is not in memory, so every read fails; existing Kubernetes Secrets (copies made by ESO) keep working, new or rotated values don't arrive; unseal with Shamir key shares, or auto-unseal (KMS, transit, HSM). [Y06]
180. **You rotated a secret in the backend. When does the app see it?** (M) - ESO `refreshInterval` updates the Secret; env vars never change (a restart is needed), mounted files update after a delay (never with `subPath`), and the app must re-read them; checksum annotation / reloader; dual-credential rotation. [Y07, C01]
181. **Two controllers write the same Secret - symptoms and fix.** (M) - the value flaps; ESO `creationPolicy` Owner / Merge / Orphan / None, ownerReferences; one source of truth per Secret, also between Sealed Secrets and ESO. [Y08]
182. **SOPS + age: how do recipients work, and what happens when someone joins or leaves?** (M) - one data key per file, wrapped for each recipient; `.sops.yaml` creation_rules only apply to new files; `sops updatekeys` re-wraps existing files; when someone leaves: rotate the data key **and** the secret values they saw. [Y09]
183. **How can a SOPS setup still leak plaintext into Git?** (S) - `path_regex` not matching, `encrypted_regex` missing `stringData`, a decrypted file committed, editor temp files; pre-commit/CI checks; once leaked, rotate - rewriting history is not enough. [Y10]
184. **Reading a Secret through the API vs mounting it in a pod - what RBAC applies?** (M) - the kubelet fetches mounted / `secretKeyRef` Secrets with node credentials (Node authorizer), so the pod's SA needs no RBAC; API reads need `get` on `secrets`; `resourceNames` limits `get` but not a plain `list`; `list` exposes every value; `create pods` in a namespace ≈ read its Secrets. [A12, A07]
185. **Encryption at rest: how do you enable it and prove it works?** (S) - EncryptionConfiguration (aescbc/aesgcm/secretbox/KMS v2); the first provider writes, all providers read, `identity` first = nothing encrypted; apiserver flag + hostPath mount; prove with `etcdctl get /registry/secrets/<ns>/<name>` (`k8s:enc:` prefix); rewrite existing Secrets; key rotation order; protect the config file. [K16]
186. **Who read this Secret? How would you find out?** (S) - an audit policy rule for `secrets` at `Metadata` (Request/RequestResponse would log the values); audit events carry user/SA, source IPs, verb, timestamp; then review who can read it (`can-i --list`, who-can). [A13, O09]

## 18. Node failure & cluster lifecycle

187. **A worker is cut off from the network. Timeline of what Kubernetes does.** (S) - the kubelet stops renewing its Lease → after `node-monitor-grace-period` (40-50 s, version-dependent) the node goes Unknown and gets the `unreachable:NoExecute` taint → pods with the default 300 s `tolerationSeconds` are deleted → controllers recreate them elsewhere; containers on the partitioned node keep running. [L11, L12]
188. **Why does a StatefulSet pod stay Terminating when its node is unreachable, and how do you recover safely?** (S) - at-most-one identity: without the kubelet's confirmation the pod object stays; fence the node first (power off, stop kubelet + containers), then force-delete or apply the `node.kubernetes.io/out-of-service` taint (also detaches volumes); force-delete without fencing risks two writers. [L11]
189. **How do you make failover faster for one critical app, and what's the risk?** (M) - shorter `tolerationSeconds` for `unreachable`/`not-ready` on its pods; flapping nodes then cause churn; taint-based eviction doesn't go through the Eviction API, so PDBs don't slow it down. [L12]
190. **A node is Ready but everything on it is slow. How do you find out why?** (M) - CPU throttling (`cpu.stat` `nr_throttled` on `kubepods.slice` / pod cgroups, `cpu.max`), steal time on VMs, disk I/O, probe timeouts; `kubectl top` shows usage, not throttling. [L13]
191. **Which node settings must survive a reboot, and how do you check?** (M) - swap off (fstab) or NodeSwap configured, modules (`overlay`, `br_netfilter`) in modules-load.d, sysctls in sysctl.d, containerd + kubelet enabled; test by rebooting; `br_netfilter` matters for bridge CNIs (flannel, bridge plugin), not for routed Calico, and recent kubeadm no longer checks it. [L14, L15]
192. **Clock skew on a node - symptoms and fix.** (M) - x509 "expired or not yet valid", SA token `nbf`/`exp` rejected, confusing log/event ordering, etcd warnings on control planes; chrony/NTP, `timedatectl`, `chronyc tracking`. [L16]
193. **The node disk is full, but `du` doesn't find the space.** (M) - deleted-but-open files (`lsof +L1`), container logs, images, journald; kubelet image GC and DiskPressure eviction. [L17, R08]
194. **conntrack table full - symptoms, cause, fix.** (S) - random new-connection timeouts, `nf_conntrack: table full, dropping packet` in dmesg, `conntrack -S` drops; kube-proxy `conntrack.maxPerCore`/`min`, storms of short connections, UDP DNS. [L18]
195. **Walk through a kubeadm upgrade 1.36 → 1.37 on 1 control plane + 3 workers.** (S) - etcd snapshot first; read the changelog and skew rules; point the package repo at the new minor; cp1: upgrade the kubeadm package, `kubeadm upgrade plan`, `kubeadm upgrade apply v1.37.x` (static pods, addons, cert renewal), drain, kubelet + kubectl, restart, uncordon; then each worker: kubeadm package, `kubeadm upgrade node`, drain, kubelet + kubectl, restart, uncordon; one minor at a time; PDBs gate the drains; check CNI/addon compatibility. [K13]
196. **What does `kubeadm join` need, and why does it fail?** (M) - a bootstrap token (24 h TTL; `kubeadm token create --print-join-command`), the discovery CA cert hash (pins the cluster CA), a reachable `controlPlaneEndpoint`; TLS bootstrap → auto-approved CSR → kubelet client cert; expired token or old CA hash = failed join. [K15]
197. **What is `controlPlaneEndpoint`, and why set it even with one control plane?** (M) - a stable DNS name / LB address baked into kubeconfigs and certs; allows HA later without re-issuing certs; the LB needs health checks against healthy backends; it must be in the apiserver cert SANs. [K14, K17]
198. **How do you add a SAN to the apiserver cert of a kubeadm cluster?** (S) - add it to `apiServer.certSANs` in the kubeadm-config ConfigMap (so upgrades keep it), move the old apiserver cert/key away, `kubeadm init phase certs apiserver --config ...`, restart the apiserver; check with `openssl x509 -noout -ext subjectAltName`. [K17]

## 19. Quick-fire (one-liners)

199. Get all pods not Running cluster-wide - `kubectl get pods -A --field-selector=status.phase!=Running`
200. Sort events by time - `kubectl get events -A --sort-by=.lastTimestamp`
201. Previous container logs - `kubectl logs <pod> -c <c> --previous`
202. Check what you can do - `kubectl auth can-i --list -n ns`
203. Which pods run on a node - `kubectl get pods -A -o wide --field-selector spec.nodeName=<node>`
204. Decode a secret - `kubectl get secret s -o jsonpath='{.data.key}' | base64 -d`
205. Restart a deployment - `kubectl rollout restart deploy/x`
206. Explain a field - `kubectl explain pod.spec.containers.livenessProbe --recursive`
207. Dry-run + diff - `kubectl diff -f x.yaml`, `kubectl apply --dry-run=server`
208. Temporary debug pod - `kubectl run tmp --rm -it --image=nicolaka/netshoot -- bash`

---

Sources used for the selection: CKA curriculum (Linux Foundation, Feb 2025 changes),
Killer Shell/Killercoda CKA troubleshooting drills, techinterview.org "what interviewers ask past
pods", kube-dojo CKA quiz, jorijn.com troubleshooting KB, k8s.af failure stories (Zalando, Preply,
Omio, Buffer, loveholidays).
