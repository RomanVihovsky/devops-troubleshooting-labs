# K02 - three mistakes in one static pod manifest

**Root cause**:
1. `--enable-admission-plugins=NodeRestriction,PodSecurityPolicy` - PSP was removed in 1.25: the API server
   exits ("plugin PodSecurityPolicy ... not registered").
2. `--tls-cert-file=/etc/kubernetes/pki/apiserver.cert` - the file is `apiserver.crt`.
3. Label `hardened-by: sec team` - a space is not a valid label value. The **kubelet** rejects the manifest
   before any container exists (`journalctl -u kubelet`: invalid pod), so `crictl` shows nothing new.

`--profiling=false` is a real CIS recommendation and stays.

**Diagnosis**: `crictl ps -a | grep apiserver`, `crictl logs <id>`, `journalctl -u kubelet | grep -i
apiserver`, `ls /etc/kubernetes/pki`.

**Interview notes**
- Static pods: the kubelet watches the directory; no API needed - and no API to tell you what's wrong. The
  kubelet journal and `crictl` are the tools.
- Fix one error at a time and re-read the logs: the API server stops at the first fatal flag.
- Never keep a backup copy in the manifests directory (kubelet runs it too); version the manifests elsewhere.
- PSA (namespace labels) replaced PodSecurityPolicy; hardening guides copied from old blogs still mention PSP.
