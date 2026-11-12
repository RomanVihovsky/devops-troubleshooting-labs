# indexer needs the SSD node - and won't start
**INC-2502** · P3 · Reporter: search team

The `indexer` (namespace `indexer`, `workspace/S02/indexer.yaml`) must run on the node with the SSD. The
platform team labelled that node last week. The pods stay **Pending**: *didn't match Pod's node
affinity/selector*. The platform team owns node labels - don't relabel nodes.

**Test**: indexer runs on the SSD node (the one the platform team labelled), and node labels are unchanged.
