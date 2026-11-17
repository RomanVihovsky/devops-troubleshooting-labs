# L17: a systemd service on w2 fallocates a huge spool file, keeps it open and deletes it -> df full, du empty
nxi k8s-w2 >/dev/null <<'__X__'
set -eu
read -r size avail < <(df -B1 --output=size,avail /var | tail -1)
alloc=$(( avail - size * 7 / 100 ))           # leave 7 % free: below the kubelet's nodefs.available 10 %
[ "$alloc" -gt 0 ]
echo "$alloc" > /etc/audit-spooler.size
cat > /usr/local/bin/audit-spooler <<'EOF'
#!/bin/bash
# audit spooler (HARD-230): preallocates its spool, rotates it by unlinking
set -eu
d=/var/log/app-audit; mkdir -p "$d"
f="$d/spool-$(date +%s).bin"
fallocate -l "$(cat /etc/audit-spooler.size)" "$f"
exec 3<"$f"
rm -f "$f"
exec sleep infinity
EOF
chmod 755 /usr/local/bin/audit-spooler
cat > /etc/systemd/system/audit-spooler.service <<'EOF'
[Unit]
Description=Application audit spooler (HARD-230)
After=local-fs.target

[Service]
ExecStart=/usr/local/bin/audit-spooler
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now audit-spooler >/dev/null 2>&1
__X__
kns audit
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: audit-ui, namespace: audit}
spec:
  replicas: 2
  selector: {matchLabels: {app: audit-ui}}
  template:
    metadata: {labels: {app: audit-ui}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w2}
      containers:
        - name: ui
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: audit-ui}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
YML
pressure() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}')" = True ]; }
retry 180 pressure || die "k8s-w2 never reported DiskPressure"
