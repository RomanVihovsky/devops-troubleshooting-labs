# web in kust-prod runs with dev settings
**INC-2604** · P2 · Reporter: SRE

`kubectl apply -k workspace/O08/overlays/prod` deploys `web` into `kust-prod` with 1 replica and `LOG_LEVEL=debug`
- the base's development defaults. The prod overlay is supposed to make it 3 replicas and `info`, and
`kubectl kustomize` shows no error at all.

**Test**: `kubectl kustomize workspace/O08/overlays/prod` renders 3 replicas and `LOG_LEVEL=info`; `web` in
`kust-prod` runs 3 Ready pods with `LOG_LEVEL=info`; the base is unchanged (still the dev defaults).
