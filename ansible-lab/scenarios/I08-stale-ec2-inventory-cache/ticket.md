# Scale-out web3 never got the release - the deploy fails on an instance terminated last week
**OPS-3204** · P2 · Reporter: release manager

Two problems with today's `deploy-prod` job (`ci/deploy.sh`):

* it fails with `UNREACHABLE` on **shop-web-9** - that instance was terminated last week - and on **shop-web-8**;
* **shop-web-3**, scaled out yesterday, isn't in the run at all: it still serves the default nginx page instead of
  release 2.3.0.

The EC2 console shows shop-web-1, -2 and -3 running, shop-web-8 stopped (kept for the OOM forensics, will be
terminated after the review), shop-web-9 terminated. The autoscaling group adds and removes web instances
several times a day now - every job has to see the fleet **as it is at that moment**.

**Test**: `ci/deploy.sh` hits exactly the running web instances and succeeds; shop-web-3 serves release 2.3.0; then
the test stops shop-web-2 and launches shop-web-4, and the very next `ci/deploy.sh` hits exactly the new fleet.
