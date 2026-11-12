# The old manifests don't apply on the new cluster
**INC-2592** · P3 · Reporter: team legacyweb

We moved `legacyweb` to this cluster. The app runs, but `kubectl apply -f workspace/O03/extras.yaml` (its PDB and
Ingress, written years ago) fails: *no matches for kind "PodDisruptionBudget" in version "policy/v1beta1"*, and the
same for the Ingress. Bring them over with their meaning intact.

**Test**: PDB `web` (policy/v1) keeps at least 1 `app: web` pod available; Ingress `web` routes `legacy.lab` to
Service `web` port 8080 and answers 200 through the LB.
