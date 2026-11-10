# nothing new starts since last night's maintenance
**INC-2506** · P2 · Reporter: notify team

Since the kernel-patch maintenance last night, our new `notify` Deployment (namespace `notify`,
`workspace/S06/notify.yaml`) stays **Pending**: *node(s) were unschedulable*. Existing pods everywhere
still run. The maintenance is finished.

**Test**: notify runs on the workers; no node is left cordoned.
