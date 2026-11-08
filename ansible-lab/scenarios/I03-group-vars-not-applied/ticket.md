# Web tier lost its settings after the inventory reorganisation
**OPS-223** · P2 · Reporter: web team

After last week's inventory reorganisation the web nodes serve on the default port 8080 instead of **8081**
and the `X-Tier: frontend` header is gone - both come from the web tier's group_vars. No errors, just a few
warnings nobody reads.

**Test**: web1 and web2 serve on 8081 with `X-Tier: frontend`; the run prints no warning about group names;
site.yml converges.
