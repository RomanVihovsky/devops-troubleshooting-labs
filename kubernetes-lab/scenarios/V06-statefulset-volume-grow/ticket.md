# tsdb is running out of disk and we can't give it more
**INC-2690** · P2 · Reporter: team observability

`tsdb` (StatefulSet, 2 replicas, `workspace/V06/tsdb.yaml`) needs 2Gi per replica instead of 1Gi. Changing
`volumeClaimTemplates` and applying fails: *spec: Forbidden: updates to statefulset spec for fields other than
'replicas', 'ordinals', 'template', ...*. The `nfs` StorageClass supports expansion. Each replica's data must
survive (no new volumes, no data copy), and future replicas must get 2Gi too.

**Test**: PVCs `data-tsdb-0` and `data-tsdb-1` are the same volumes as before and now 2Gi (requested and
provisioned); the StatefulSet's template asks for 2Gi; both pods are Ready and still return their data.
