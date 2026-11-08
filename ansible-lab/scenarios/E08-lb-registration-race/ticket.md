# After the LB rebuild only one web node is in rotation - every deploy is green
**OPS-3221** · P2 · Reporter: on-call

lb1 was rebuilt from the golden image last night (empty backend registry - expected, the deploy re-registers the
nodes since NET-77). The 06:00 deploy was green, all three web nodes reported `added` in "Register in the load
balancer" - but lb1 only sends traffic to **one** of them. The 06:30 deploy (green again) left two. In prod (60 web
nodes, same playbook) this would take ages to converge, and every LB failover starts from an empty registry.

`lb-register` is the network team's tool (vendored in `files/`) - we can't change it. The deploy must stay
parallel: 60 nodes one at a time is not an option. Only the LB registration may be slower.

**Test**: starting from an empty registry (as after a rebuild), **one** deploy registers web1, web2 and web3, and haproxy
on lb1 has all three UP; `lb-register` is unchanged (repo and lb1); the deploy is not serialized (no play-level
`serial`/`throttle`, forks > 1); a second deploy changes nothing.
