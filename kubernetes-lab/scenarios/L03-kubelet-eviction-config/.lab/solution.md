# L03 - an invalid quantity in the KubeletConfiguration

**Root cause**: `evictionHard: {memory.available: 200MB}` - `MB` is not a Kubernetes quantity suffix. The
kubelet fails while parsing its eviction thresholds and exits; systemd restarts it every 10 s.

**Diagnosis**: `journalctl -u kubelet -n 50` on the node ("failed to parse eviction thresholds" /
quantities must match ...).

**Fix**: `200Mi` (or `200M`), restart the kubelet.

**Interview notes**
- The kubelet's config is `/var/lib/kubelet/config.yaml` (+ drop-ins in `--config-dir`), flags in
  `kubeadm-flags.env`; cluster-wide defaults live in the `kubelet-config` ConfigMap and are written by
  `kubeadm join/upgrade` - a node-local edit is overwritten by the next `kubeadm upgrade node`.
- Hard eviction (`evictionHard`) kills pods immediately below the threshold; soft eviction has grace
  periods. Pods are ranked by QoS and usage above requests (R domain).
- Roll config changes node by node and watch `journalctl -u kubelet` before moving on.
