## Hint 1
There is more than one fault. Work the request path: `web` -> DNS lookup of `catalog` -> the Service -> catalog's pods.
`kubectl -n bf logs deploy/web`, `kubectl -n bf get endpointslices`, `kubectl -n bf get networkpolicy`.

## Hint 2
Checklist: does the Service select catalog's pods (labels)? Is DNS (kube-system, UDP/TCP 53) allowed out of the
namespace? `kubectl -n bf describe hpa catalog` (why no metric?). `kubectl -n bf get pdb` (ALLOWED DISRUPTIONS).

## Hint 3
Fix the selector; add an egress policy to kube-dns on 53; give catalog's container a CPU request; set the PDB to
`maxUnavailable: 1` (or `minAvailable: 2`). Don't touch `default-deny`.
