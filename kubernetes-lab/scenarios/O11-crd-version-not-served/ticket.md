# widget-reporter is down since the widgets CRD went to v2
**INC-2726** · P2 · Reporter: team factory

The platform team upgraded the `widgets.example.lab` CRD to v2 this morning (`workspace/O11/widgets-crd.yaml`).
Since then `widget-reporter` - and every script that still asks for `widgets.v1.example.lab` - gets *404 the server
could not find the requested resource*. v1 clients have one more quarter. Also, the platform team wants to delete
v1 next quarter and asks that by then **no widget is still stored as v1** in etcd.

**Test**: `widget-reporter` is Ready (the v1 API answers); all widgets in `factory` are readable as v1 and as v2,
with their data; v2 stays the storage version; every widget is stored as v2 in etcd and the CRD's
`status.storedVersions` lists only v2.
