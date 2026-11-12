# The new analytics service never starts
**INC-2529** · P3 · Reporter: team analytics

`analytics` (`workspace/R06/analytics.yaml`, 2 replicas) stays Pending: *Insufficient memory*. The nodes use a
third of their memory. The resource settings were "copied from the VM it ran on before" (8 GB). In the cluster it
uses about 100 MiB - give it requests that fit what it really uses (with headroom) and keep a memory limit.

**Test**: `analytics` has 2 Running pods; each container requests at most 512Mi of memory and still has a memory
request and a memory limit.
