# gateway: scaled to 5 for the sale, only 3 run
**INC-2504** · P2 · Reporter: platform team

We scaled `gateway` (namespace `gateway`, `workspace/S04/gateway.yaml`) to 5 replicas for the sale. Three
run, two stay **Pending**. We still want the replicas spread over the workers as evenly as possible.

**Test**: 5 gateway pods Running and Ready, spread over all 3 workers.
