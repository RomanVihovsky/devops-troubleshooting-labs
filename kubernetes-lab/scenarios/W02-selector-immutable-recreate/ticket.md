# search v2 can't be deployed
**INC-2475** · P3 · Reporter: team search

The v2 manifest (`workspace/W02/search-v2.yaml`) adds a `tier: web` label everywhere - selector included - and
greets with "Search v2". `kubectl apply` fails: *spec.selector: Invalid value ... field is immutable*. We accept a
short interruption tonight. Deploy v2 as written.

**Test**: Deployment `search` uses the v2 selector (`app: search, tier: web`) and runs 2 Ready pods that greet
"Search v2"; Service `search` sends traffic to them (it has endpoints and answers 200).
