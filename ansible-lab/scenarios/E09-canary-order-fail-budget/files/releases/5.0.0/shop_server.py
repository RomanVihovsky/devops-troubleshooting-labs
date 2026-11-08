#!/usr/bin/env python3
"""ACME shop server (stand-in): answers GET with its version. 5.0.0: new routing (needs Python >= 3.10)."""
import http.server

VERSION = "5.0.0"


def route(path):
    match path:
        case "/health":
            return "ok"
        case _:
            return f"shop {VERSION}"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = (route(self.path) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


http.server.HTTPServer(("0.0.0.0", 8090), Handler).serve_forever()
