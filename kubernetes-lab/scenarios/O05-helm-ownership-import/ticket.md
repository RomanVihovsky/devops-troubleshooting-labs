# helm install web fails on an existing Service
**INC-2598** · P3 · Reporter: team importx

We're moving `web` (namespace `importx`) from hand-written manifests to our chart. The Service `web` already exists
(other teams call it - it must not disappear, not even for a moment). `helm install web charts/labapp -n importx
-f workspace/O05/values.yaml` fails: *Service "web" in namespace "importx" exists and cannot be imported into the
current release: invalid ownership metadata*.

**Test**: release `web` is deployed from the chart; the Service `web` is the same object as before (not re-created)
and now belongs to the release; `web` has 2 Ready pods behind it.
