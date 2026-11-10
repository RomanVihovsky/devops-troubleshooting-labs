# render workers never start
**INC-2501** · P3 · Reporter: media team

The new `render` Deployment (namespace `render`, `workspace/S01/render.yaml`) stays **Pending**:
*0/4 nodes are available: Insufficient cpu*. The cluster is almost idle. The service needs about a tenth of
a CPU per pod in practice.

**Test**: render's pods are Running and Ready, each requesting less than 1 CPU.
