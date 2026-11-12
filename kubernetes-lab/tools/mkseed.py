#!/usr/bin/env python3
"""mkseed.py - build the generic cloud-init NoCloud seed ISO (label "cidata") for the lab VMs.

  PYTHONPATH=cache/pypi/pycdlib-<v>-py3-none-any.whl python3 tools/mkseed.py \
      --nodes infra/vbox/nodes.csv --pubkey .state/labvm_key.pub --out .state/kit/seed.iso

One ISO serves every VM: user-data creates user `lab` with the desktop's key and installs
k8slab-identity (hostname + /etc/hosts from the NIC2 MAC); network-config pins both NICs of every
node by MAC (NAT = DHCP, host-only = static IP). `--check FILE` lists an existing ISO instead.
"""
import argparse
import csv
import hashlib
import io
import os
import sys
import time
from pathlib import Path

import pycdlib

ROOT = Path(__file__).resolve().parent.parent
# Reproducible ISOs: pycdlib stamps time.time() into the volume and directory records. A fixed clock in UTC
# means the same content gives the same bytes, so the committed infra/vbox/seed.iso only changes when
# its content does.
FIXED_EPOCH = 1735689600.0   # 2025-01-01T00:00:00Z
CI = ROOT / "infra" / "cloud-init"


def nodes(path):
    rows = []
    with open(path, newline="") as f:
        for r in csv.reader(f):
            if not r or r[0].startswith("#"):
                continue
            name, cpus, mem, ip, mac1, mac2, role = (x.strip() for x in r)
            rows.append(dict(name=name, ip=ip, mac1=mac1, mac2=mac2, role=role))
    return rows


def colon_mac(m):
    m = m.lower()
    return ":".join(m[i:i + 2] for i in range(0, 12, 2))


def indent(text, n):
    pad = " " * n
    return "\n".join(pad + line if line else "" for line in text.rstrip("\n").split("\n"))


def build(args):
    rows = nodes(args.nodes)
    pubkey = Path(args.pubkey).read_text().strip()
    csv_text = Path(args.nodes).read_text()
    user_data = (CI / "user-data.yaml").read_text()
    user_data = user_data.replace("@@PUBKEY@@", pubkey)
    user_data = user_data.replace("@@NODES_CSV@@", indent(csv_text, 6))
    user_data = user_data.replace("@@IDENTITY@@", indent((CI / "k8slab-identity.sh").read_text(), 6))

    net = ["version: 2", "ethernets:"]
    for r in rows:
        net += [
            f"  {r['name']}-nat:",
            f"    match: {{macaddress: \"{colon_mac(r['mac1'])}\"}}",
            "    dhcp4: true",
            "    optional: true",
            f"  {r['name']}-lab:",
            f"    match: {{macaddress: \"{colon_mac(r['mac2'])}\"}}",
            "    dhcp4: false",
            f"    addresses: [{r['ip']}/24]",
            "    optional: true",
        ]
    network = "\n".join(net) + "\n"

    digest = hashlib.sha256((user_data + network).encode()).hexdigest()[:12]
    meta = f"instance-id: k8slab-{digest}\nlocal-hostname: k8slab\n"

    try:  # validate what we can before writing
        import yaml
        for label, text in (("user-data", user_data), ("network-config", network), ("meta-data", meta)):
            if not isinstance(yaml.safe_load(text), dict):
                sys.exit(f"mkseed: {label} is not a YAML mapping")
    except ImportError:
        pass

    files = [("meta-data", meta), ("user-data", user_data), ("network-config", network)]
    os.environ["TZ"] = "UTC"
    time.tzset()
    time.time = lambda: FIXED_EPOCH
    iso = pycdlib.PyCdlib()
    iso.new(interchange_level=3, joliet=3, rock_ridge="1.09", vol_ident="cidata")
    for name, text in files:
        data = text.encode()
        iso9660 = "/" + name.upper().replace("-", "") + ".;1"
        iso.add_fp(io.BytesIO(data), len(data), iso9660, rr_name=name, joliet_path="/" + name)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    iso.write(str(out))
    iso.close()
    print(f"{out}: {len(rows)} nodes, instance-id k8slab-{digest}")


def check(path):
    iso = pycdlib.PyCdlib()
    iso.open(path)
    print("volume:", iso.pvd.volume_identifier.decode().strip())
    for name in ("meta-data", "user-data", "network-config"):
        buf = io.BytesIO()
        iso.get_file_from_iso_fp(buf, rr_path="/" + name)
        print(f"--- {name} ({len(buf.getvalue())} bytes)")
        if name != "user-data":
            print(buf.getvalue().decode().rstrip())
    iso.close()


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--nodes", default=str(ROOT / "infra/vbox/nodes.csv"))
    p.add_argument("--pubkey", default=str(ROOT / ".state/labvm_key.pub"))
    p.add_argument("--out", default=str(ROOT / ".state/kit/seed.iso"))
    p.add_argument("--check", metavar="ISO")
    args = p.parse_args()
    if args.check:
        check(args.check)
    else:
        build(args)


if __name__ == "__main__":
    main()
