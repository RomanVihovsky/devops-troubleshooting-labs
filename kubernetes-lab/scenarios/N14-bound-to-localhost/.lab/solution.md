# N14 - the app listens on 127.0.0.1

**Root cause**: `BIND_ADDRESS=127.0.0.1`. Inside the pod's network namespace, loopback is only reachable
from the pod itself (and port-forward, which connects there). Service traffic arrives at the pod IP:
connection refused. The exec readiness probe also uses localhost, so the pods look Ready.

**Fix**: bind to 0.0.0.0 (all interfaces of the *pod's* namespace) and control access with NetworkPolicy.

**Interview notes**
- "Works with port-forward, not via the Service" → bind address, or a targetPort mismatch (N02).
- httpGet/tcpSocket probes come from the kubelet to the pod IP - they would have caught this; exec probes
  run inside the container.
