sxi <<'S'
useradd --system --no-create-home --shell /usr/sbin/nologin inventory
mkdir -p /opt/inventory /etc/inventory
cat > /opt/inventory/api.py <<'A'
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
port = int(os.environ.get("PORT", "8083"))
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers(); self.wfile.write(b"inventory ok\n")
print(f"inventory-api on :{port} as uid {os.getuid()}", flush=True)
HTTPServer(("0.0.0.0", port), H).serve_forever()
A
echo 'PORT=8083' > /etc/inventory/api.env
cat > /etc/systemd/system/inventory-api.service <<'U'
[Unit]
Description=Inventory API
After=network.target
StartLimitBurst=3

[Service]
User=inventry
EnvironmentFile=/etc/inventory/api.env
ExecStart=/usr/bin/python3 /opt/inventory/bin/api.py
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload && systemctl enable inventory-api; systemctl start inventory-api || true
S
