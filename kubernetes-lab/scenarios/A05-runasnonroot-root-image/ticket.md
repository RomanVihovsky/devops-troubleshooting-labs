# payments-ui blocked by "runAsNonRoot"
**INC-2805** · P2 · Reporter: payments team

`payments-ui` (namespace `payments-ui`, `workspace/A05/payments-ui.yaml`) fails with
**CreateContainerConfigError**: *container has runAsNonRoot and image will run as root*. Security requires
non-root - that setting stays. The labapp image also exists in a non-root build.

**Test**: payments-ui is Ready, `runAsNonRoot: true` is still set, and the container really runs as a
non-root user.
