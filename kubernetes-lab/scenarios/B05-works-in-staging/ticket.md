# web is fine in staging, broken in prod
**INC-2942** · P2 · Reporter: team web

We promoted `web` from `web-staging` to `web-prod` with the same manifests (`workspace/B05/web.yaml`, only the
namespace and the host changed). Staging runs on the ARM test nodes and pulls from the public mirror; prod must pull
from the authenticated registry `registry.lab:5001` (the pull credentials are in Secret `regcred` in `web-staging`).
In prod nothing starts and `http://web.prod.lab` is a 404.

**Test**: `web` runs 2 Ready pods in `web-prod` from `registry.lab:5001`; `http://web.prod.lab/` answers 200 through the
cluster's ingress with the greeting from its config; staging is untouched.
