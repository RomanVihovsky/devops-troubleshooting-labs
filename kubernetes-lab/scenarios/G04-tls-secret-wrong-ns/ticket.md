# secure.lab shows a certificate warning
**INC-2553** · P2 · Reporter: security

`https://secure.lab` (Ingress in namespace `secure`, `workspace/G04/secure.yaml`) presents *TRAEFIK DEFAULT CERT*
instead of our certificate from the lab CA. The certificate and key are in the TLS Secret `secure-tls` - we
created it this morning, and `kubectl get secret secure-tls` shows it. (Files: `workspace/G04/secure.crt`, `.key`.)

**Test**: `https://secure.lab/` (via 192.168.56.200:443) answers 200 with a certificate for `secure.lab` that the
lab CA verifies.
