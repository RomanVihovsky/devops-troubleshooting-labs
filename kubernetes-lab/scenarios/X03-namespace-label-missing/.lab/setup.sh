# X03: the policy admits namespaces labelled team=monitoring; "monitoring" lacks the label
kns appx monitoring otherx
kx -n appx create deployment metrics-api --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml | ka -f -
kx -n appx create service clusterip metrics-api --tcp=8080:8080 --dry-run=client -o yaml | ka -f -
wait_rollout appx deploy/metrics-api
ka -f allow-monitoring.yaml
remember x03_spec "$(kx -n appx get networkpolicy allow-monitoring -o jsonpath='{.spec}')"
! tcp_ok_as monitoring - metrics-api.appx.svc:8080 || die "monitoring already connects"
