#!/usr/bin/env python3
"""ACME shop server (stand-in): answers GET with its version."""
import http.server

VERSION = "4.2.0"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = f"shop {VERSION}\n".encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


http.server.HTTPServer(("0.0.0.0", 8090), Handler).serve_forever()
