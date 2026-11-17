# image-scanner floods CoreDNS with NXDOMAIN
**INC-2652** · P3 · Reporter: platform team

CoreDNS's NXDOMAIN rate went through the roof when `image-scanner` (`workspace/N08/image-scanner.yaml`) went
live. Each request it serves makes one call to the registry API at `registry.lab:5000`, and that works - but
CoreDNS logs a handful of lookups like `registry.lab.scanner.svc.cluster.local` failing for every single call.
Make the scanner's lookups cheap. It must keep calling the registry by its name (no IP addresses, no hand-made
`/etc/hosts` entries); CoreDNS is shared and stays as it is.

**Test**: under 20 s of load on `image-scanner` every request succeeds and CoreDNS answers fewer than 1
NXDOMAIN per request; the scanner still calls `registry.lab` by name, without `hostAliases`.
