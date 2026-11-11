# web-prod has 1 pod and logs every health check
**INC-2346** · P2 · Reporter: SRE

Since yesterday's "shared defaults" cleanup, `web-prod` runs a single pod with `LOG_LEVEL=debug`, exactly like
`web-dev`. Prod's values file still says 3 replicas and `info` - we checked twice. Make prod render prod's
values again without changing what dev gets.

**Test**: web-prod has 3 Ready pods with `LOG_LEVEL=info`; web-dev still has 1 pod with `LOG_LEVEL=debug`;
both apps are Synced + Healthy; the fix is in Git, and neither environment's values file was emptied to get
there (prod's file still says 3 / info).
