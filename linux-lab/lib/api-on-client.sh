# start a tiny HTTP API on lnx-client :8080 that answers "api OK" (used by DNS scenarios)
start_client_api() {
  cx "systemd-run --unit=internal-api --quiet python3 -c '
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers(); self.wfile.write(b\"api OK\\n\")
HTTPServer((\"0.0.0.0\", 8080), H).serve_forever()'"
  retry 15 sx 'curl -fs --max-time 2 http://10.77.0.20:8080/'
}
