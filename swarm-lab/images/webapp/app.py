"""Tiny stdlib-only web app used by every lab scenario.

Behaviour is driven by environment variables that look like ordinary app
settings (REDIS_HOST, LOG_LEVEL, SESSION_DIR ...). Endpoints:
  GET /         greeting + redis hit counter (if REDIS_HOST is set)
  GET /health   checks every configured dependency, 200 or 503
  GET /big?kb=N returns N KiB of payload
"""
import hashlib
import os
import signal
import socket
import sys
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

ENV = os.environ.get
HOSTNAME = socket.gethostname()
VERSION = ENV("APP_VERSION", "1.0")
NAME = ENV("APP_NAME", "webapp")
PORT = int(ENV("PORT", "8000"))
REDIS_HOST = ENV("REDIS_HOST")
REDIS_PORT = int(ENV("REDIS_PORT", "6379"))
REDIS_PASSWORD_FILE = ENV("REDIS_PASSWORD_FILE")
UPSTREAM_URL = ENV("UPSTREAM_URL")
DATA_DIR = ENV("DATA_DIR")
SESSION_DIR = ENV("SESSION_DIR")
SESSION_SNAPSHOT = int(ENV("SESSION_SNAPSHOT", "0"))
LOG_FILE = ENV("LOG_FILE")
LOG_LEVEL = ENV("LOG_LEVEL", "info")
LOG_MAX_MB = int(ENV("LOG_MAX_MB", "16"))
CACHE_WARMUP_MB = int(ENV("CACHE_WARMUP_MB", "0"))
SELFTEST_ROUNDS = int(ENV("SELFTEST_ROUNDS", "0"))
GREETING_FILE = ENV("GREETING_FILE")

_cache = None
_logf = None
_redis_password = None


def log(msg):
    print(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} [{NAME}] {msg}", flush=True)


def fatal(msg):
    log(f"FATAL: {msg}")
    sys.exit(1)


# --- redis (minimal RESP client) -------------------------------------------
def redis_cmd(*args):
    def enc(parts):
        out = f"*{len(parts)}\r\n"
        for p in parts:
            p = str(p)
            out += f"${len(p.encode())}\r\n{p}\r\n"
        return out.encode()

    with socket.create_connection((REDIS_HOST, REDIS_PORT), timeout=2) as s:
        f = s.makefile("rb")
        if _redis_password is not None:
            s.sendall(enc(["AUTH", _redis_password]))
            line = f.readline().decode().strip()
            if not line.startswith("+OK"):
                raise RuntimeError(f"redis AUTH failed: {line}")
        s.sendall(enc(args))
        line = f.readline().decode().strip()
        if line.startswith("-"):
            raise RuntimeError(f"redis error: {line[1:]}")
        return line[1:]


# --- background "features" ----------------------------------------------------
def debug_logger():
    """Verbose debug logging that keeps writing to LOG_FILE."""
    chunk = ("DEBUG " + "x" * 1018 + "\n") * 256  # ~256 KiB
    while True:
        try:
            _logf.write(chunk)
            _logf.flush()
        except OSError:
            time.sleep(1)
        time.sleep(0.1)


def log_housekeeping():
    """'Rotates' LOG_FILE when it grows beyond LOG_MAX_MB."""
    while True:
        time.sleep(5)
        try:
            if os.path.getsize(LOG_FILE) > LOG_MAX_MB * 1024 * 1024:
                os.remove(LOG_FILE)
                log(f"housekeeping: rotated {LOG_FILE}")
        except OSError:
            pass


def restore_sessions():
    os.makedirs(SESSION_DIR, exist_ok=True)
    restored = 0
    for i in range(SESSION_SNAPSHOT):
        try:
            with open(os.path.join(SESSION_DIR, f"sess_{i:06d}"), "w") as f:
                f.write("u=guest;ttl=0\n")
            restored += 1
        except OSError:
            break
    log(f"restored {restored} sessions into {SESSION_DIR}")


# --- health -------------------------------------------------------------------
def health():
    problems = []
    if SELFTEST_ROUNDS:
        h = b"selftest"
        for _ in range(SELFTEST_ROUNDS):
            h = hashlib.sha256(h).digest()
    if REDIS_HOST:
        try:
            redis_cmd("PING")
        except Exception as e:  # noqa: BLE001
            problems.append(f"redis {REDIS_HOST}:{REDIS_PORT}: {e}")
    if UPSTREAM_URL:
        try:
            urllib.request.urlopen(UPSTREAM_URL, timeout=3).read()
        except Exception as e:  # noqa: BLE001
            problems.append(f"upstream {UPSTREAM_URL}: {e}")
    if DATA_DIR:
        try:
            # atomic write: temp file + rename (needs fresh blocks every time)
            tmp = os.path.join(DATA_DIR, f".heartbeat.{HOSTNAME}")
            with open(tmp, "w") as f:
                f.write(f"{time.time()}\n")
            os.replace(tmp, os.path.join(DATA_DIR, "heartbeat"))
        except OSError as e:
            problems.append(f"cannot write heartbeat: {e}")
    if SESSION_DIR:
        probe = os.path.join(SESSION_DIR, f"probe_{HOSTNAME}")
        try:
            with open(probe, "w") as f:
                f.write("ok")
            os.remove(probe)
        except OSError as e:
            problems.append(f"cannot create session: {e}")
    return problems


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, code, body, ctype="text/plain"):
        data = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):  # noqa: N802
        url = urlparse(self.path)
        if url.path == "/health":
            problems = health()
            if problems:
                log("health FAILED: " + "; ".join(problems))
                return self._send(503, "unhealthy: " + "; ".join(problems) + "\n")
            return self._send(200, "ok\n")
        if url.path == "/big":
            kb = int(parse_qs(url.query).get("kb", ["256"])[0])
            return self._send(200, b"z" * (kb * 1024), "application/octet-stream")
        greeting = "Hello"
        if GREETING_FILE:
            try:
                with open(GREETING_FILE) as f:
                    greeting = f.read().strip()
            except OSError as e:
                return self._send(500, f"cannot read greeting: {e}\n")
        msg = f"{greeting} from {HOSTNAME} ({NAME} v{VERSION})"
        if REDIS_HOST:
            try:
                msg += f" hits={redis_cmd('INCR', 'hits')}"
            except Exception as e:  # noqa: BLE001
                log(f"ERROR redis: {e}")
                return self._send(502, f"{msg} redis error: {e}\n")
        return self._send(200, msg + "\n")

    def log_message(self, fmt, *args):
        if _logf is not None:
            try:
                _logf.write(f"{self.address_string()} {fmt % args}\n")
            except OSError:
                pass


def on_sigterm(*_):
    log("SIGTERM received, shutting down gracefully")
    sys.exit(0)


def main():
    global _cache, _logf, _redis_password
    signal.signal(signal.SIGTERM, on_sigterm)
    log(f"starting {NAME} v{VERSION} on :{PORT} (pid {os.getpid()})")

    if REDIS_PASSWORD_FILE:
        try:
            with open(REDIS_PASSWORD_FILE) as f:
                _redis_password = f.read().strip()
        except OSError as e:
            fatal(f"cannot read redis password: {e}")
    if CACHE_WARMUP_MB:
        log(f"warming up in-memory cache ({CACHE_WARMUP_MB} MiB)...")
        _cache = b"c" * (CACHE_WARMUP_MB * 1024 * 1024)
        log("cache ready")
    if SESSION_DIR and SESSION_SNAPSHOT:
        restore_sessions()
    if LOG_FILE:
        _logf = open(LOG_FILE, "a")
        threading.Thread(target=log_housekeeping, daemon=True).start()
        if LOG_LEVEL == "debug":
            threading.Thread(target=debug_logger, daemon=True).start()
    if REDIS_HOST:
        try:
            redis_cmd("PING")
            log(f"connected to redis {REDIS_HOST}:{REDIS_PORT}")
        except Exception as e:  # noqa: BLE001
            log(f"WARN redis not reachable yet: {e}")

    serve()


class DualStackServer(ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        super().server_bind()


def serve():
    # listen on IPv4 and IPv6 so both 127.0.0.1 and ::1 ("localhost") work
    try:
        server = DualStackServer(("::", PORT), Handler)
    except OSError:
        server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    server.serve_forever()


if __name__ == "__main__":
    main()
