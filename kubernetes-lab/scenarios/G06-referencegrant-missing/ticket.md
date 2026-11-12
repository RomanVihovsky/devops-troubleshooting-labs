# frontdoor.lab: 500, route says RefNotPermitted
**INC-2559** · P2 · Reporter: team web

Our HTTPRoute `web-front/frontdoor` (`workspace/G06/route.yaml`, on the shared Gateway `traefik/traefik-gateway`)
sends `frontdoor.lab` to the Service `api` in namespace `web-back` (owned by the backend team). The route says
*ResolvedRefs: False, RefNotPermitted*. The backend team agrees to let **routes from `web-front`** use their
Services - nothing more. The Service stays in `web-back`.

**Test**: `frontdoor.lab` answers 200 from `web-back/api` through the LB; the route's references resolve; the
backend still lives in `web-back`.
