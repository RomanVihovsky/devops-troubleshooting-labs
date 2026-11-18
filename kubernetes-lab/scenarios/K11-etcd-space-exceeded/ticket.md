# The cluster is read-only
**INC-2830** · P1 · Reporter: on-call

Since about ten minutes ago nothing can be created or changed: *etcdserver: mvcc: database space exceeded*. Nodes are
turning NotReady. The new `import` job had just started caching its batches as ConfigMaps in namespace `import` - that
was a bad idea, they are not needed. Someone also "tuned" etcd's storage limit last week. Get the cluster writable
again and keep it that way.

**Test**: etcd has no active alarm and accepts writes; its backend quota is the default or at least 1 GiB; namespace
`import` has no cache ConfigMaps left; all nodes are Ready.
