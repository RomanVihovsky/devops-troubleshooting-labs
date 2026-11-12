# catalog.lab is unreachable after the move to the new Service
**INC-2547** · P2 · Reporter: team catalog

Since we "standardised" our Service (`workspace/G02/catalog.yaml`), `catalog.lab` answers 404 through the ingress.
The pods are Ready, the Service has endpoints, and Traefik's log says *Cannot create service: service port not
found*. Keep the Service as it is (other clients use its port 8080).

**Test**: `catalog.lab` answers 200 through the Ingress; Service `catalog` still exposes port 8080.
