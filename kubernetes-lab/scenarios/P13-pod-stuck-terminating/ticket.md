# A queue-worker pod has been Terminating for ages
**INC-2460** · P3 · Reporter: on-call

I deleted a stuck `queue-worker` pod (namespace `queue`) twenty minutes ago. `kubectl delete` hung, I hit Ctrl-C,
and the pod is still *Terminating*; its replacement already runs. The "cleanup operator" that some of our pods
were registered with was uninstalled last month. Make the pod go away **properly**, and make sure the next
rollout of `queue-worker` (`workspace/P13/queue-worker.yaml`) doesn't hang for ten minutes per pod.

**Test**: no `queue-worker` pod is Terminating and none carries the `example.com/cleanup` finalizer;
`queue-worker` has 1 Ready pod; its pods shut down gracefully on SIGTERM (`SHUTDOWN_MODE` is not `ignore`) within
a grace period of at most 60 s.
