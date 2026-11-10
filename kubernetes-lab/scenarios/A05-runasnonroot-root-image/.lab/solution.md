# A05 - runAsNonRoot vs a root image

**Root cause**: the `1.4-root` image's USER is 0; `runAsNonRoot: true` makes the kubelet refuse to start it
(CreateContainerConfigError: "image will run as root").

**Fix**: the non-root build (`1.4`), keeping `runAsNonRoot`.

**Interview notes**
- runAsNonRoot is checked by the kubelet against the image's USER (numeric) or `runAsUser`. A named USER
  ("app") can't be verified → also rejected unless `runAsUser` is set.
- PSA `restricted` requires runAsNonRoot, no privilege escalation, dropped capabilities, seccomp
  RuntimeDefault (A04, T16).
