# PR "hand the ML datasets bucket to the data team" would delete it
**INFRA-188** · P1 · Reporter: data team lead

The data team takes over `acme-ml-datasets` (they will import it into their own stack next week).
The PR simply removes the bucket from `stacks/platform-shared` - and the plan says **destroy**. Those
are 18 months of curated training data.

Get the bucket out of this stack without touching it.

**Test**: the bucket and its versioning are no longer in this stack's state; the bucket still exists
with its files; a CI plan shows no changes.
