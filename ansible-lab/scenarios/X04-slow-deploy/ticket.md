# Deploy takes 20+ minutes on the 40-node fleet - and grows with every node
**OPS-340** · P3 · Reporter: release manager

`ci/deploy.sh` time grows linearly with the fleet. Here, with only 4 nodes, a run that changes **nothing**
already takes ~30 s. Nothing in the playbook is slow on its own.

**Test**: a no-change run of site.yml (4 nodes, cold SSH connections) finishes in under 15 s; same result on
the nodes; site.yml converges; host key checking stays on.
