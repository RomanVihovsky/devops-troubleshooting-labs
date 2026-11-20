## Hint 1
Plan before you drain: `kubectl get pdb -A` - how many storefront pods may be disrupted at once
(`ALLOWED DISRUPTIONS`)? A drain evicts through the Eviction API, which respects PDBs and retries forever.

## Hint 2
`minAvailable: 3` with 3 replicas allows **zero** voluntary disruptions - no drain can ever finish. Change it to
`minAvailable: 2` (or `maxUnavailable: 1`); with pods on three different workers, one can always move.

## Hint 3
The upgrade itself (the learn lab T09 walks through it): on cp1 `apt-get install kubeadm=1.37.*`,
`kubeadm upgrade plan`, `kubeadm upgrade apply v1.37.x`, then drain -> kubelet + kubectl -> restart -> uncordon;
on each worker `kubeadm upgrade node`, then the same drain/kubelet/uncordon - **one node at a time**, waiting for
storefront to be 3/3 Ready before the next drain.
