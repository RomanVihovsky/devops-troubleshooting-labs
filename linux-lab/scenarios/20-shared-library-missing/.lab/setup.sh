sxi <<'S'
mkdir -p /opt/vendor/lib /var/lib/report
mv /usr/lib/x86_64-linux-gnu/libjq.so.1* /opt/vendor/lib/
ldconfig
cat > /etc/systemd/system/report.service <<'U'
[Unit]
Description=Nightly report

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'jq --version > /var/lib/report/last-run'
U
systemctl daemon-reload
systemctl start report.service || true
S
