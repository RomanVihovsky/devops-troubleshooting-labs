sxi <<'S'
mkdir -p /var/log/app /usr/lib/systemd-telemetry
cat > /usr/lib/systemd-telemetry/telemetryd <<'A'
#!/bin/bash
exec 3>>/var/log/app/events.log
while true; do echo "$(date -Is) beacon host=$(hostname) seq=$RANDOM" >&3; sleep 1; done
A
chmod 755 /usr/lib/systemd-telemetry/telemetryd
cat > /etc/systemd/system/systemd-telemetry.service <<'U'
[Unit]
Description=System Telemetry Collector

[Service]
ExecStart=/usr/lib/systemd-telemetry/telemetryd
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload && systemctl enable --now systemd-telemetry
S
sleep 2
