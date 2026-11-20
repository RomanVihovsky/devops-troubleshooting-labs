runtime_ok() { [ "$(nx k8s-w3 'cat /proc/sys/net/netfilter/nf_conntrack_max' </dev/null 2>/dev/null)" -ge 131072 ]; }
boot_ok() {
  nx k8s-w3 'grep -hs "^[[:space:]]*net.netfilter.nf_conntrack_max" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf' </dev/null 2>/dev/null \
    | awk -F= '{ gsub(/ /, "", $2); if ($2 + 0 < 131072) bad = 1 } END { exit bad }'
}
# a load pod pinned to w3 (absolute name: no DNS search noise), short connections for 45 s
r=$(KX_TIMEOUT='' kx -n quotes run "lab-load-$RANDOM" --rm -i --restart=Never --quiet --image="$LABAPP_IMAGE" \
      --labels="$LAB_LABEL=$LAB_ID" --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"k8s-w3"}}}' \
      --command -- labapp load http://quotes.quotes.svc.cluster.local.:8080/ -q -c 16 -d 45 --rps 220 --timeout 3 2>/dev/null | grep '^{' | tail -1)
r=${r:-"{}"}
summary=$(jq -r '"\(.requests // 0) requests, \(.errors // "?") failed"' <<<"$r")
clean() { jq -e '.requests > 3000 and .errors == 0' <<<"$r" >/dev/null; }
check "nf_conntrack_max on w3 is >= 131072" runtime_ok
check "no sysctl file on w3 sets it lower (survives a reboot)" boot_ok
check "45 s of load from k8s-w3: no failed request ($summary)" clean
verdict
