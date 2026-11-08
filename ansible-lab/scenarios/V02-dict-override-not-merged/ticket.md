# Prod responses got 4x bigger after raising the upload limit
**OPS-244** · P2 · Reporter: performance team

Yesterday prod got a bigger upload limit (`group_vars/prod.yml`). Since then prod serves everything
**uncompressed** and closes connections immediately - staging is fine. The change was one line.

**Test**: prod (web1) has gzip on, keepalive 65 and the 50m upload limit; staging (web2) keeps 10m; changing a
shared default in `group_vars/all.yml` still reaches prod; no global `hash_behaviour = merge`; site.yml converges.
