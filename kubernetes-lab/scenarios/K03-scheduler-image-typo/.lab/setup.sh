# K03: kube-schedular (typo) - the image doesn't exist, no scheduler runs
nx "$CP" "sed -i 's|/kube-scheduler:|/kube-schedular:|' /etc/kubernetes/manifests/kube-scheduler.yaml && grep -q kube-schedular /etc/kubernetes/manifests/kube-scheduler.yaml" </dev/null
gone() { ! nx "$CP" "crictl ps --name kube-scheduler -q | grep -q ." </dev/null; }
retry 120 gone || die "the scheduler kept running"
kns ops
kx -n ops create deployment batch --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --dry-run=client -o yaml | ka -f -
pending() { [ "$(kx -n ops get pods -l app=batch --field-selector=status.phase=Pending --no-headers | wc -l)" = 2 ]; }
retry 60 pending || die "batch pods not Pending"
