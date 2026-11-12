sed -i 's/tolerationSeconds: 3600/tolerationSeconds: 60/' api.yaml
kx apply -f api.yaml >/dev/null
ready_away() {
  [ "$(kx -n checkout get pods -l app=api -o json | jq '[.items[] | select(.spec.nodeName != "k8s-w2" and .metadata.deletionTimestamp == null
      and any(.status.conditions[]?; .type == "Ready" and .status == "True"))] | length')" -ge 3 ]
}
retry 240 ready_away || true
