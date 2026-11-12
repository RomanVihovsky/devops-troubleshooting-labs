# T01 · Lab tour: the kit, ./lab, the nodes, the UIs and the reset ladder
**Learn** · where everything runs, how you reach it, how labs are reset · ~20 min

The cluster runs in 5 VirtualBox VMs next to this desktop: `k8s-gw` (API load balancer, registry, Git,
OpenBao, NFS), `k8s-cp1` (control plane) and `k8s-w1..3`. They were created on the Windows host by the kit
(`k8slab.bat status | stop | snapshot | restore`); `./lab` only reaches them over SSH and the API.
Fill in `workspace/T01/answers.yaml` as you go.

1. `./lab ui` lists every endpoint and where its credentials live. `eval "$(./lab env)"` puts kubectl,
   helm, argocd, kubeseal, bao and sops for this cluster into your shell.
2. `kubectl get nodes -o wide -L topology.kubernetes.io/zone`: note the **containerd version on k8s-w2**
   and the **zone of k8s-w3**.
3. `kubectl get svc -A` and `kubectl get storageclass`: the **LoadBalancer IP of the Argo CD UI** and the
   **default StorageClass**.
4. `./lab node gw` (a root-capable shell on k8s-gw): every API request goes through haproxy there. Find in
   `/etc/haproxy/haproxy.cfg` **where it sends the API traffic** (`ip:port`).
5. `./lab list`: each lab declares how it is reset before the next one starts (`ns`, `node`, `gw`,
   `cluster` - see docs/FAULTS.md). Note the **reset level of the incident L01**.
6. Run something: in namespace `t01`, a Deployment `hello` with 2 replicas of
   `registry.lab:5000/lab/labapp:1.4` (port 8080) and a Service `hello` on port 80. Test it from inside the
   cluster with a throwaway busybox pod (`docker.io/library/busybox:1.37`).

**Test**: the 6 answers match the live lab; `t01/hello` has 2 ready replicas of labapp 1.4 and
`http://hello.t01/` answers 200 from inside the cluster.
