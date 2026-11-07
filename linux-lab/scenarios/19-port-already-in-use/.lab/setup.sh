sxi <<'S'
cat > /usr/local/bin/legacy-status <<'A'
#!/bin/bash
read -r _line
printf 'HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\nlegacy status page OK\n'
A
chmod 755 /usr/local/bin/legacy-status
cat > /etc/systemd/system/legacy-status.socket <<'U'
[Unit]
Description=Legacy status page (socket)

[Socket]
ListenStream=80
Accept=yes

[Install]
WantedBy=sockets.target
U
cat > /etc/systemd/system/legacy-status@.service <<'U'
[Unit]
Description=Legacy status page (connection)

[Service]
ExecStart=/usr/local/bin/legacy-status
StandardInput=socket
StandardError=journal
U
systemctl stop nginx
systemctl daemon-reload && systemctl enable --now legacy-status.socket
systemctl start nginx || true
S
