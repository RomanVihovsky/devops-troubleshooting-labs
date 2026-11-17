## Hint 1
`kubectl -n shipping describe pod <pending pod>` - the event isn't about labapp's image. Which image does every pod
need *before* its containers start?

## Hint 2
Each pod's sandbox ("pause" container) is created from containerd's **sandbox image**: `./lab node w2`,
`grep -n -A3 pinned_images /etc/containerd/config.toml`, and `crictl images | grep pause`.

## Hint 3
Point `sandbox` back to an image the node can get - `registry.k8s.io/pause:3.10.2` (mirrored by the lab registry,
already cached) - and `systemctl restart containerd`. The kubelet retries the stuck pods by itself.
