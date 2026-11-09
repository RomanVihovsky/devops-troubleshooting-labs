# k8s-w2 is NotReady since last night's maintenance
**INC-1077** · P2 · Reporter: platform on-call

The patching run finished at 02:10. Since then `kubectl get nodes` shows **k8s-w2 NotReady**; its pods
were rescheduled elsewhere and the node takes no new work. The VM is up - you can log in with
`./lab node w2`. The patch runbook says "stop node services, patch, reboot", and nobody remembers the
reboot step.

**Test**: k8s-w2 is Ready and runs pods again, and it will come back by itself after the next reboot.
