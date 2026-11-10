# N02 - targetPort points at a port nobody listens on

**Root cause**: `targetPort: 80`; the container listens on 8080. kube-proxy DNATs to podIP:80 → RST →
connection refused (a timeout would mean no endpoints or a NetworkPolicy).

**Fix**: `targetPort: http` (named) or 8080.

**Interview notes**
- refused = something answered "no listener" (wrong port, app bound to 127.0.0.1 - N14); timeout = nothing
  answered (no endpoints, NetworkPolicy, routing).
- Named target ports decouple the Service from port numbers.
