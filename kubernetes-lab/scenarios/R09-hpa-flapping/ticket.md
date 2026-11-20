# catalog-api thrashes between 2 and 6 pods
**INC-2647** · P3 · Reporter: team catalog

Our traffic comes in bursts (the `traffic-replay` Deployment reproduces production: 25 s of load, 35 s quiet).
Since someone "tuned" the autoscaler (`workspace/R09/catalog-api.yaml`), `catalog-api` scales up for every burst
and back down right after it - every minute, all day. Each new pod spends 10 s warming its cache, so the next
burst always hits cold pods. Scale-up speed is fine; the scale-down is the problem. The HPA's limits (2-6
replicas) and its 50 % CPU target are agreed with finance and stay.

**Test**: with `traffic-replay` running, the HPA does not scale `catalog-api` down at any point during
150 s; the HPA still targets `catalog-api` with 2-6 replicas at 50 % CPU.
