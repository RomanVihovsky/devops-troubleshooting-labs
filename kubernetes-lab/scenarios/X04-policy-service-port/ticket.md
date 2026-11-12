# web unreachable although the policy allows its port
**INC-2577** · P2 · Reporter: team portx

Service `web` listens on port 80 (`workspace/X04/web.yaml`). The policy `web-ingress` allows TCP 80 from the
namespace, yet `curl http://web.portx.svc` from a pod in `portx` times out. Only the web port may be open.

**Test**: pods in `portx` connect to `web.portx.svc:80`; the policy still lists exactly one allowed port (the
one web serves on).
