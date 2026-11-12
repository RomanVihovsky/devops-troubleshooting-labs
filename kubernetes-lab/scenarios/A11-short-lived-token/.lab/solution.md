# A11 - a bound, expiring token used as a CI credential

**Root cause**: the pipeline's token came from the TokenRequest API, **bound** to the runner pod `runner-7f9c`
(that's what `kubectl create token --bound-object-kind=Pod` or a pod's projected token gives you). The API server
checks the bound object on every request: once the runner pod was recycled, the token was invalid (401), even
before its `exp`.

**Diagnosis**
```
cut -d. -f2 workspace/A11/ci-token.txt | tr '_-' '/+' | base64 -d 2>/dev/null | jq '{exp, "kubernetes.io"}'   # pod: runner-7f9c
kubectl -n ci2 get pod runner-7f9c        # NotFound
```

**Fix** (as security allowed): a Secret of type `kubernetes.io/service-account-token` annotated
`kubernetes.io/service-account.name: ci-bot`. The token controller fills in a non-expiring token. It's valid as
long as the Secret and the ServiceAccount exist; rotate it by deleting/recreating the Secret.

**Interview notes**
- Since 1.24 ServiceAccounts no longer get token Secrets automatically. Pods get short-lived, audience-bound,
  auto-rotated projected tokens. That's the secure default.
- Long-lived tokens are standing credentials. Prefer the CI system's own identity (OIDC federation: GitHub
  Actions/GitLab → cluster OIDC, or a cloud IAM role) or `kubectl create token --duration` per pipeline run.
- 401 = the token isn't valid (expired, bound object gone, wrong audience, wrong cluster); 403 = valid but RBAC
  says no.
