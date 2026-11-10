# thumbs: only one of two replicas runs
**INC-2704** · P2 · Reporter: media team

`thumbs` (namespace `thumbs`, `workspace/V04/thumbs.yaml`) needs 2 replicas on **different nodes**, each with
its own local cache volume. The second replica stays **Pending**: *volume node affinity conflict*.

**Test**: 2 thumbs pods Ready on two different nodes, each with its own PVC on local-path.
