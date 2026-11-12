# Prometheus can't scrape appx
**INC-2574** · P3 · Reporter: observability

`appx` only accepts connections from the monitoring team's namespace (`workspace/X03/allow-monitoring.yaml`). Our
scrapers run in namespace `monitoring` and time out on `metrics-api.appx.svc:8080`. Any other namespace (e.g.
`otherx`) must stay blocked, and the policy itself is the platform standard - don't edit it.

**Test**: pods in `monitoring` connect to `metrics-api.appx.svc:8080`; pods in `otherx` don't; the policy is
unchanged.
