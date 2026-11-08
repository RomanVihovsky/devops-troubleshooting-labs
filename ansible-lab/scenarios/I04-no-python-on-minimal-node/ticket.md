# New node app1 fails every task - "python3: not found"
**OPS-231** · P2 · Reporter: platform

`app1` is the first node built from the new **minimal** Debian image (smaller attack surface, no Python).
`ansible-playbook site.yml` now fails on app1 at fact gathering. More nodes from that image are coming next
week - fixing app1 by hand is not the answer.

**Test**: site.yml configures app1; when the lab strips Python from another node, `site.yml` alone brings it back
and configures it; site.yml converges.
