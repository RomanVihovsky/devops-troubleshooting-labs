# units and files outside the golden node paths: the node reset doesn't know them
nxi k8s-w2 >/dev/null 2>&1 <<'__X__'
systemctl disable --now audit-spooler 2>/dev/null
rm -f /etc/systemd/system/audit-spooler.service /usr/local/bin/audit-spooler /etc/audit-spooler.size
rm -rf /var/log/app-audit
systemctl daemon-reload
true
__X__
true
