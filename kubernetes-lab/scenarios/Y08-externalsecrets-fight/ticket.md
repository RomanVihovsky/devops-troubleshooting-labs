# The partner API key keeps changing back to the revoked one
**INC-2741** · P1 · Reporter: team partners

We moved the partner API key to its new OpenBao path `partners/api` (the old key at `partners/legacy` is revoked
by the partner tomorrow). Secret `api-key` in `partners` now flips between the new and the old value every few
seconds - our calls fail half of the time. The app `partners` is managed by Argo CD
(`workspace/gitops/envs/partners/`); Secret `api-key` was created by hand when the integration started.

**Test**: exactly one ExternalSecret writes Secret `api-key`: `api-key`, which owns the Secret (`creationPolicy:
Owner`); the Secret holds the new key and keeps it for 90 s; the legacy ExternalSecret is gone from Git; app
`partners` is Synced and Healthy.
