f_l2_node() {
  local n
  n=$(kx -n metallb-system get servicel2statuses -o json 2>/dev/null \
      | jq -r '.items[] | select(.status.serviceName == "hello-lb" and .status.serviceNamespace == "t06") | .status.node' | head -1)
  [ -n "$n" ] || n=$(kx -n t06 get events --field-selector involvedObject.name=hello-lb -o json 2>/dev/null \
      | jq -r '[.items[] | select(.reason == "nodeAssigned")] | last | .message // ""' | grep -o 'k8s-[a-z0-9]*' | head -1)
  echo "$n"
}
