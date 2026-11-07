sxi <<'S'
mkdir -p /opt/metrics-api
cat > /etc/metrics-api.conf <<'A'
# metrics-api
bind = 127.0.0.1
port = 8090
A
cat > /opt/metrics-api/api.py <<'A'
import configparser
from http.server import BaseHTTPRequestHandler, HTTPServer
cfg = configparser.ConfigParser(); cfg.read_string("[x]\n" + open("/etc/metrics-api.conf").read())
bind, port = cfg["x"]["bind"], int(cfg["x"]["port"])
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers(); self.wfile.write(b"metrics ok\n")
HTTPServer((bind, port), H).serve_forever()
A
cat > /etc/systemd/system/metrics-api.service <<'U'
[Unit]
Description=Metrics API
[Service]
ExecStart=/usr/bin/python3 /opt/metrics-api/api.py
Restart=always
[Install]
WantedBy=multi-user.target
U
cat > /etc/systemd/system/node-exporter.service <<'U'
[Unit]
Description=Node exporter (internal only)
[Service]
ExecStart=/usr/bin/python3 -m http.server 9100 --directory /var/empty
Restart=always
[Install]
WantedBy=multi-user.target
U
mkdir -p /var/empty
systemctl daemon-reload && systemctl enable --now metrics-api node-exporter
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 8090 -j DROP
iptables -A INPUT -p tcp --dport 9100 -j DROP
S
