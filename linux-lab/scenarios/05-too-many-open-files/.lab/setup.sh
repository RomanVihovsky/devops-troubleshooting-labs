sxi <<'S'
mkdir -p /opt/catalog-api /var/lib/catalog/shards
for i in $(seq 1 300); do echo "shard $i" > /var/lib/catalog/shards/$i.dat; done
cat > /opt/catalog-api/api.py <<'A'
# catalog-api: keeps every shard file open for fast lookups
import glob
from http.server import BaseHTTPRequestHandler, HTTPServer
shards = [open(f) for f in sorted(glob.glob("/var/lib/catalog/shards/*.dat"))]
print(f"catalog-api: {len(shards)} shards open, listening on :8081", flush=True)
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers()
        self.wfile.write(f"catalog ok, {len(shards)} shards\n".encode())
HTTPServer(("0.0.0.0", 8081), H).serve_forever()
A
cat > /etc/systemd/system/catalog-api.service <<'U'
[Unit]
Description=Catalog API

[Service]
ExecStart=/usr/bin/python3 /opt/catalog-api/api.py
User=deploy
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
U
mkdir -p /etc/systemd/system/catalog-api.service.d
cat > /etc/systemd/system/catalog-api.service.d/hardening.conf <<'U'
# CIS-style hardening baseline (SEC-88)
[Service]
NoNewPrivileges=yes
LimitNOFILE=256
U
cat >> /etc/security/limits.conf <<'A'
# INC-4410: raise fd limit for catalog-api
*    soft    nofile    65535
*    hard    nofile    65535
A
systemctl daemon-reload && systemctl enable --now catalog-api
S
sleep 3
