# X09 - default deny without the allows

**Root cause**: `default-deny` isolates every shop pod in both directions - no DNS, no frontend → api, no
api → postgres/redis, and Traefik can't reach the frontend. `default-deny-egress` cuts ESO off from DNS,
OpenBao and the API server.

**Fix** (on top of security's policies):
- shop: allow DNS for all pods; frontend ← traefik :8080, frontend → api :8080; api ← frontend, api →
  postgres :5432 + redis :6379; postgres/redis ← api.
- external-secrets: egress to DNS, OpenBao `192.168.56.20/32:8200`, the API `192.168.56.21/32:6443`.

**Interview notes**
- Rollout order for zero trust: observe (Calico flow logs / Hubble), write allows, *then* the deny - or deny
  egress last. DNS is always the first casualty.
- NetworkPolicy matches post-DNAT addresses: Services are transparent (you select pods), but the API server
  and anything on host networking need its real IP and port.
- Policies are additive allow-lists; a pod selected by any policy for a direction is isolated in that
  direction.
