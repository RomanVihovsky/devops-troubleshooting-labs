# P07 - command overrides the entrypoint with a binary that isn't there

**Root cause**: `command: [gunicorn, ...]` replaces the image's ENTRYPOINT; the image has no `gunicorn`
(labapp is a stdlib-only Python server started by its own entrypoint). The runtime fails at exec:
RunContainerError / StartError.

**Diagnosis**: `kubectl describe pod` (exec: "gunicorn": executable file not found in $PATH); inspect the
image's entrypoint (`crane config registry.lab:5000/lab/labapp:1.4 | jq .config.Entrypoint,.config.Cmd`).

**Fix**: drop the override (or call a binary that exists).

**Interview notes**
- `command` ↔ ENTRYPOINT, `args` ↔ CMD. Setting only `args` keeps the entrypoint.
- Debug a container that can't start: `kubectl debug -it <pod> --image=busybox --target=<container>` or a
  copy with `--copy-to ... -- sh`.
