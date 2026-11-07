sxi <<'S'
mkdir -p /opt/login-api
python3 - <<'P'
import os, time
d = "/var/lib/app/sessions"
old = time.time() - 10 * 86400
n = 0
while True:
    p = f"{d}/sess_{n:06d}"
    try:
        with open(p, "w") as f: f.write("user=guest;expired")
    except OSError:
        break
    os.utime(p, (old, old)); n += 1
for i in range(15):                              # 15 live sessions
    os.remove(f"{d}/sess_{i:06d}")
    with open(f"{d}/live_{i:02d}", "w") as f: f.write(f"user=u{i};active")
P
cat > /opt/login-api/api.py <<'A'
import uuid
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with open(f"/var/lib/app/sessions/sess_{uuid.uuid4().hex}", "w") as f:
                f.write("user=new")
            code, msg = 200, "session created\n"
        except OSError as e:
            code, msg = 500, f"login failed: {e}\n"
        self.send_response(code); self.end_headers(); self.wfile.write(msg.encode())
HTTPServer(("0.0.0.0", 8082), H).serve_forever()
A
cat > /etc/systemd/system/login-api.service <<'U'
[Unit]
Description=Login API

[Service]
ExecStart=/usr/bin/python3 /opt/login-api/api.py
Restart=always

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload && systemctl enable --now login-api
S
retry 20 sx 'curl -s localhost:8082/login | grep -q "No space"'
