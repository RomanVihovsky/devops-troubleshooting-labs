# N11: kube-proxy excluded from k8s-w2 by node affinity; a Service created afterwards has no rules on w2
kx -n kube-system patch ds kube-proxy --type merge -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"NotIn","values":["k8s-w2"]}]}]}}}}}}}' >/dev/null
gone() { [ -z "$(kx -n kube-system get pods -l k8s-app=kube-proxy --field-selector spec.nodeName=k8s-w2 -o name 2>/dev/null)" ]; }
retry 180 gone || die "kube-proxy still runs on k8s-w2"
rolled() { [ "$(kx -n kube-system get ds kube-proxy -o jsonpath='{.status.numberReady}/{.status.desiredNumberScheduled}')" = 3/3 ]; }
retry 180 rolled || die "kube-proxy did not settle on the other nodes"
kns pricing
kx -n pricing create deployment pricing --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --dry-run=client -o yaml | ka -f -
kx -n pricing create service clusterip pricing --tcp=8080:8080 --dry-run=client -o yaml | ka -f -
wait_rollout pricing deploy/pricing
