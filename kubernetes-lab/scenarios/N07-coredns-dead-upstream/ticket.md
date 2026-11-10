# external DNS broken in all pods
**INC-2607** · P2 · Reporter: integrations team

Since the network team's "new corporate DNS" change, pods resolve cluster names fine, but every external
name (`pkgs.k8s.io`, partner APIs) times out. The nodes themselves resolve external names without trouble.

**Test**: pods resolve external names again (and cluster names still work); CoreDNS is Ready.
