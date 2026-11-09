#!/usr/bin/env python3
"""calico-patch.py IN OUT POD_CIDR NODE_CIDR - adapt the upstream calico.yaml to the lab:
  * VXLAN overlay, no BGP: calico_backend "vxlan", pool IPIP Never / VXLAN Always, BIRD probes removed
  * pod CIDR set (CALICO_IPV4POOL_CIDR)
  * IP autodetection by CIDR (cidr=NODE_CIDR): every VM's NAT NIC is 10.0.2.15, and NIC names differ
    between hypervisors (enp0s8 / ens8) - so pick the address on the host-only network
"""
import sys
import yaml

src, dst, pod_cidr, node_cidr = sys.argv[1:5]
docs = [d for d in yaml.safe_load_all(open(src)) if d]
found = set()


def set_env(env, name, value):
    for e in env:
        if e.get("name") == name:
            e.clear()
            e.update(name=name, value=value)
            return
    env.append({"name": name, "value": value})


for d in docs:
    kind, name = d.get("kind"), d.get("metadata", {}).get("name")
    if kind == "ConfigMap" and name == "calico-config":
        d["data"]["calico_backend"] = "vxlan"
        found.add("configmap")
    if kind == "DaemonSet" and name == "calico-node":
        for c in d["spec"]["template"]["spec"]["containers"]:
            if c["name"] != "calico-node":
                continue
            env = c.setdefault("env", [])
            set_env(env, "CALICO_IPV4POOL_IPIP", "Never")
            set_env(env, "CALICO_IPV4POOL_VXLAN", "Always")
            set_env(env, "CALICO_IPV4POOL_CIDR", pod_cidr)
            set_env(env, "IP_AUTODETECTION_METHOD", "cidr=" + node_cidr)
            for probe in ("livenessProbe", "readinessProbe"):
                cmd = c.get(probe, {}).get("exec", {}).get("command")
                if cmd:
                    cmd[:] = [a for a in cmd if "bird" not in a]
            found.add("daemonset")

missing = {"configmap", "daemonset"} - found
if missing:
    sys.exit("calico-patch: not found in %s: %s" % (src, ", ".join(sorted(missing))))
with open(dst, "w") as f:
    yaml.safe_dump_all(docs, f, sort_keys=False, width=200)
print("calico patched: vxlan, pod CIDR %s, autodetect cidr=%s" % (pod_cidr, node_cidr))
