# A03 - no token mounted

**Root cause**: the janitor ServiceAccount has `automountServiceAccountToken: false`: no projected token at
`/var/run/secrets/kubernetes.io/serviceaccount`. Requests go out without credentials → 401 (or 403 as
`system:anonymous`).

**Fix**: opt in where needed - `automountServiceAccountToken: true` in the janitor pod spec (pod setting
overrides the SA).

**Interview notes**
- Hygiene done right: automount off by default (on `default` SAs), on for the few workloads that call the
  API.
- Projected tokens are short-lived (1 h, refreshed by the kubelet) and audience-bound; clients must re-read
  the file (A11 is the "token expired after an hour" ticket).
