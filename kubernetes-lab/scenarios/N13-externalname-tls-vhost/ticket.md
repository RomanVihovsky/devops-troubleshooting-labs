# frontend can't reach vendor search through our alias
**INC-2660** · P2 · Reporter: team frontend

The vendor's search API runs in namespace `vendor` (HTTPS on 8443, certificate from the lab CA, virtual hosts).
To be able to move it later we gave it a stable name in our namespace: Service `search`, type ExternalName,
pointing at `search.vendor.svc.cluster.local` (`workspace/N13/frontend.yaml`). Since then `frontend` is NotReady:
*certificate verify failed: Hostname mismatch*. Someone tried setting `UPSTREAM_HOST` to the vendor's name and
that didn't help either. The vendor deployment, its certificate and its virtual-host list are not ours to change,
and we won't turn TLS verification off.

**Test**: `frontend` runs 2 Ready pods (its upstream check passes) and still calls the vendor over `https` with
the lab CA; the vendor's deployment and certificate are unchanged.
