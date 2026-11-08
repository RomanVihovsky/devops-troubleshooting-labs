# Postmortem: release 2.0.0-rc1 took the whole site down for 4 minutes
**PM-90** · P1 · Reporter: incident commander

Yesterday `ansible-playbook deploy.yml -e app_release=2.0.0-rc1` shipped a broken build (its nginx
snippet was invalid). All three web nodes restarted at the same time, nginx failed everywhere, and
`lb1` answered 503 until someone redeployed 1.4.2.

Bad builds will happen again. Make `deploy.yml` safe: a broken release may break **at most one** node, the
site must keep answering through `lb1` the whole time, and the deploy must stop at the first failure.
Healthy deploys must still update all nodes and leave every node in the load balancer.

**Test**: the lab replays the 2.0.0-rc1 deploy while hammering `http://lb1/` - zero failed requests, at most
one node touched, the play stops; afterwards a 1.4.2 deploy brings all three nodes back into rotation and
everything converges.
