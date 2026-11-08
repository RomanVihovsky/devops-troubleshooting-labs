#!/bin/bash
# k8slab-identity - first boot of a kubernetes-lab VM: find this VM in /etc/k8slab/nodes.csv by the
# MAC of its host-only NIC, then set the hostname and /etc/hosts. The static IP itself comes from the
# seed's network-config (netplan, matched by the same MAC). Idempotent; runs once from cloud-init.
set -eu
csv=/etc/k8slab/nodes.csv
macs=$(cat /sys/class/net/*/address)
me="" myip=""
hosts=""
while IFS=, read -r name _cpus _mem ip _mac1 mac2 role; do
  case $name in ''|\#*) continue ;; esac
  role=${role%$'\r'}
  aliases=""
  [ "$role" = gw ] && aliases=" gw.lab k8s-api.lab registry.lab git.lab bao.lab"
  hosts+="$ip $name$aliases"$'\n'
  mac=$(echo "$mac2" | sed 's/../&:/g; s/:$//' | tr 'A-F' 'a-f')
  if grep -qx "$mac" <<<"$macs"; then me=$name; myip=$ip; fi
done < "$csv"
if [ -z "$me" ]; then
  echo "k8slab-identity: no NIC of this VM matches $csv" >&2
  exit 1
fi
hostnamectl set-hostname "$me"
cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
# kubernetes-lab nodes (host-only network) - from $csv
$hosts
EOF
# keep the netplan written on first boot even if the seed ISO is detached later
echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-k8slab-network.cfg
echo "k8slab-identity: $me $myip"
