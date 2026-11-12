# K10: "--v=2" added to the scheduler manifest with a TAB for indentation - the kubelet can't parse the file
nxi "$CP" >/dev/null <<'__X__'
set -eu
f=/etc/kubernetes/manifests/kube-scheduler.yaml
cp "$f" /var/tmp/kube-scheduler.yaml
python3 - <<'PY'
p = "/var/tmp/kube-scheduler.yaml"; lines = open(p).read().split("\n")
i = next(n for n, l in enumerate(lines) if l.strip().startswith("- --leader-elect"))
lines.insert(i + 1, "\t- --v=2")
open(p, "w").write("\n".join(lines))
PY
! python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' /var/tmp/kube-scheduler.yaml 2>/dev/null
mv /var/tmp/kube-scheduler.yaml "$f"
__X__
gone() { ! nx "$CP" "crictl ps --name kube-scheduler -q | grep -q ." </dev/null && ! kx -n kube-system get pod "kube-scheduler-$CP" >/dev/null 2>&1; }
retry 180 gone || die "the scheduler is still there"
kns ops
kx -n ops create deployment reports --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --dry-run=client -o yaml | ka -f -
pending() { [ "$(kx -n ops get pods -l app=reports --field-selector=status.phase=Pending --no-headers | wc -l)" = 2 ]; }
retry 60 pending || die "reports pods not Pending"
