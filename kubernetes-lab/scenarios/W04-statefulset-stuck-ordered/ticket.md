# quorum never gets past its first member
**INC-2481** · P2 · Reporter: team quorum

The StatefulSet `quorum` (`workspace/W04/quorum.yaml`) should run 3 members. Only `quorum-0` exists, *Running* but
`0/1` Ready, and `quorum-1` is never created. We changed the readiness check this morning. Keep the members
starting one after another (`OrderedReady`) and keep a readiness probe.

**Test**: `quorum` has 3/3 Ready members; it still uses `OrderedReady` and a readiness probe.
