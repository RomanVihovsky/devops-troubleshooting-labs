# shop down since the "zero trust" change
**INC-2280** · P1 · Reporter: on-call

Security rolled out default-deny NetworkPolicies this morning: `default-deny` in `shop` (in + out) and
`default-deny-egress` in `external-secrets`. Since then `shop.lab` fails and ESO alerts that it can't reach
OpenBao. Security's policies stay - add the minimum on top. Pods are selected by `app.kubernetes.io/name`.

**Test**: both default-deny policies are unchanged; shop.lab works end to end; ESO can refresh
`shop-secrets` from OpenBao again; inside shop only the real flows work (Traefik → frontend → api →
postgres/redis) - e.g. the frontend can't reach postgres, and the api can't reach k8s-gw:22.
