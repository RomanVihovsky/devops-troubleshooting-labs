# Release 5.0.0 broke two nodes - the canary should have caught it
**PM-231** · P1 · Reporter: incident commander

Yesterday `ansible-playbook deploy.yml -e shop_release=5.0.0` broke the shop on **app2 and web2** (5.0.0 needs
Python 3.10, our Rocky nodes have 3.9). We rolled back to 4.2.0. The deploy was supposed to protect us:

* **web2 is the canary** - first in the inventory, 1 % of the traffic. It goes first and alone; if the release fails
  there, nothing else may be touched.
* after the canary, batches of two; a batch with a failed node must **stop the rollout**.

Instead app1 went first, and the run carried on after app2 failed. Next in line is 5.0.1, a hotfix cherry-picked
from an old branch - nobody is sure about it. Fix the deploy so these rules hold; healthy releases must still reach
all four nodes.

**Test**: 5.0.0 (fails on Rocky) reaches only web2 and the run stops; 5.0.1 (fails on Debian) passes the canary,
fails in the next batch - and web1 never gets it; 4.2.0 reaches all four nodes in between and at the end;
deploy.yml converges.
