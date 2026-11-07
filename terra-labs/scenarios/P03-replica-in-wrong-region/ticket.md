# DR audit: the "Ireland" replica bucket is in Frankfurt
**AUDIT-17** · P2 · Reporter: compliance

The disaster recovery audit found that `acme-media-replica` - our DR copy, which must live in
`eu-west-1` - is in `eu-central-1`, next to the primary. `stacks/media-dr` even configures an
`aws.dr` provider for Ireland. The replica is empty (replication isn't switched on yet), so it may be
recreated. The primary bucket must not be touched.

**Test**: `acme-media-replica` is in eu-west-1; the primary is unchanged; the module is wired to the
DR provider; a CI plan shows no changes.
