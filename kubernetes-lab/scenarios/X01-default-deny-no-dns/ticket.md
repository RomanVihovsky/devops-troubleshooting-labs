# client can't reach backend since the network policies went live
**INC-2568** · P2 · Reporter: security engineering

We rolled out default-deny in namespace `zt` (`workspace/X01/policies.yaml`): deny everything, then allow
`client` → `backend` on 8080. Since then `client` fails to call `backend` (`client`'s `/upstream` shows the
error). Fix it **without** loosening the model: default-deny stays, and `client` must not reach anything else
(e.g. `192.168.56.20:8080`).

**Test**: `client`'s `/upstream` (it calls `http://backend.zt.svc:8080/`) answers 200; the default-deny policy is
unchanged; `client` still can't open `192.168.56.20:8080`.
