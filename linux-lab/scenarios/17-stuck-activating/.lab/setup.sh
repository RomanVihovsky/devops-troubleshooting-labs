sxi <<'S'
mkdir -p /opt/cachewarm
cat > /opt/cachewarm/server.py <<'A'
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers(); self.wfile.write(b"cache warm\n")
print("cachewarm: serving on :8084", flush=True)
HTTPServer(("0.0.0.0", 8084), H).serve_forever()
A
cat > /etc/systemd/system/cachewarm.service <<'U'
[Unit]
Description=Cache warmer (migrated from /etc/init.d/cachewarm)

[Service]
Type=forking
PIDFile=/run/cachewarm.pid
ExecStart=/usr/bin/python3 /opt/cachewarm/server.py
TimeoutStartSec=15
Restart=on-failure

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload && systemctl enable cachewarm && systemctl start --no-block cachewarm
S
