#!/usr/bin/env python3
"""labapp - the kubernetes-lab demo service. One file, Python stdlib only.

Behaviour is driven by environment variables that look like ordinary application
settings (README.md has the full table). Scenarios inject faults by setting them.

Subcommands:
  labapp [serve] [--bind ADDR] [--port N]   HTTP service (default)
  labapp migrate                            create + seed the items schema, then exit 0
  labapp get URL [-X M] [-H 'K: V'] [-d D]  tiny curl: body to stdout, exit 0 on 2xx/3xx
  labapp load URL [-c N] [-d SEC] [--rps N] load generator, prints a JSON summary
  labapp wait-for HOST[:PORT]               wait for DNS (and TCP) - init containers
  labapp ship-logs FILE                     follow a log file to stdout - sidecars
  labapp read-secret [NS/]NAME              read a Secret via the API (ServiceAccount RBAC)
  labapp version
"""
import argparse
import base64
import hashlib
import hmac
import json
import os
import queue
import random
import re
import signal
import socket
import socketserver
import ssl
import struct
import sys
import threading
import time
import traceback
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler

VERSION = os.environ.get("APP_VERSION", "1.4")
HOSTNAME = socket.gethostname()
STARTED = time.time()
MIB = 1024 * 1024
SA_DIR = "/var/run/secrets/kubernetes.io/serviceaccount"
SECRET_NAME = re.compile(r"PASS|SECRET|TOKEN|PRIVATE|CREDENTIAL|API_?KEY|ACCESS_?KEY", re.I)
URL_WITH_USERINFO = re.compile(r"^([a-z][a-z0-9+.-]*://)([^/@]*)@", re.I)
SERVICE_LINK = re.compile(r"^[A-Z0-9_]+_(SERVICE_HOST|SERVICE_PORT(_[A-Z0-9_]+)?|PORT_\d+_(TCP|UDP|SCTP)(_PROTO|_PORT|_ADDR)?)$")


# --------------------------------------------------------------------------- logging
class Log:
    LEVELS = {"debug": 10, "info": 20, "warn": 30, "warning": 30, "error": 40}

    def __init__(self):
        self.level, self.fmt, self.out, self.lock = 20, "text", sys.stdout, threading.Lock()

    def setup(self, level, fmt, path):
        self.level = self.LEVELS.get(level.lower(), 20)
        self.fmt = "json" if fmt.lower() == "json" else "text"
        if path:
            self.out = open(path, "a", buffering=1)  # caller turns OSError into FATAL

    def emit(self, level, msg, **fields):
        if self.LEVELS[level] < self.level:
            return
        now = time.time()
        ts = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(now)) + f".{int(now * 1000) % 1000:03d}Z"
        if self.fmt == "json":
            line = json.dumps({"ts": ts, "level": level, "host": HOSTNAME, "msg": msg, **fields})
        else:
            extra = " ".join(f"{k}={v}" for k, v in fields.items())
            line = f"{ts} {level.upper():5} {msg}" + (f" {extra}" if extra else "")
        with self.lock:
            try:
                self.out.write(line + "\n")
                self.out.flush()
            except (OSError, ValueError):
                pass


LOG = Log()


def log(level, msg, **fields):
    LOG.emit(level, msg, **fields)


def fatal(msg, code=1):
    LOG.emit("error", f"FATAL: {msg}")
    if LOG.out is not sys.stdout:
        print(f"FATAL: {msg}", file=sys.stderr, flush=True)
    sys.stdout.flush()
    os._exit(code)


# --------------------------------------------------------------------------- settings
def env(name, default=""):
    return os.environ.get(name, default)


def env_int(name, default):
    raw = os.environ.get(name, "")
    if raw == "":
        return default
    try:
        return int(raw)
    except ValueError:
        fatal(f"invalid integer for {name}: {raw!r}")


def env_float(name, default):
    raw = os.environ.get(name, "")
    if raw == "":
        return default
    try:
        return float(raw)
    except ValueError:
        fatal(f"invalid number for {name}: {raw!r}")


def env_bool(name, default):
    raw = os.environ.get(name, "")
    if raw == "":
        return default
    return raw.strip().lower() in ("1", "true", "yes", "on")


def env_list(name, default=""):
    return [x.strip() for x in os.environ.get(name, default).split(",") if x.strip()]


def secret(name):
    """Value of NAME, or the content of the file named by NAME_FILE (re-read on every
    call so rotated, file-mounted secrets are picked up). Never stripped: a trailing
    newline in a Secret is passed on as-is, exactly like a careless real app."""
    if name in os.environ:
        return os.environ[name]
    path = os.environ.get(name + "_FILE")
    if path:
        try:
            with open(path) as f:
                return f.read()
        except OSError:
            return None
    if CFG is not None and CFG.credentials_secret:
        try:
            return credentials()[1].get(name.lower().replace("_", "-"))
        except Exception:  # noqa: BLE001 - logged by credentials()
            return None
    return None


def secret_presence(name):
    if name in os.environ:
        return "<set>" if os.environ[name] else "<empty>"
    path = os.environ.get(name + "_FILE")
    if path:
        return f"<set via file {path}>" if os.path.exists(path) else f"<missing file {path}>"
    if CFG is not None and CFG.credentials_secret:
        try:
            ref, data = credentials()
        except Exception as e:  # noqa: BLE001
            return f"<unreadable: {e}>" if name in ("AUTH_TOKEN", "DATABASE_URL") else None
        if name.lower().replace("_", "-") in data:
            return f"<set via Kubernetes API secret {ref}>"
    return None


_CRED_CACHE = {"at": 0.0, "value": None, "error": None}


def credentials():
    """CREDENTIALS_SECRET=[namespace/]name: read that Secret through the Kubernetes API with the
    pod's ServiceAccount token (needs RBAC `get secrets`, unlike secretKeyRef/volume mounts).
    Keys map to settings: redis-password -> REDIS_PASSWORD. Cached 30 s (errors 10 s)."""
    now = time.monotonic()
    c = _CRED_CACHE
    if now - c["at"] < (30 if c["error"] is None else 10):
        if c["error"]:
            raise RuntimeError(c["error"])
        return c["value"]
    ns, _, name = CFG.credentials_secret.rpartition("/")
    ns = ns or pod_namespace()
    try:
        obj = k8s_get(f"/api/v1/namespaces/{ns}/secrets/{name}")
        data = {k: base64.b64decode(v).decode(errors="replace") for k, v in (obj.get("data") or {}).items()}
        c.update(at=now, value=(f"{ns}/{name}", data), error=None)
        return c["value"]
    except Exception as e:  # noqa: BLE001
        if c["error"] != str(e):
            log("error", f"cannot read credentials secret {ns}/{name}: {e}")
        c.update(at=now, value=None, error=str(e))
        raise


class Settings:
    def __init__(self, args):
        self.name = env("APP_NAME", "labapp")
        self.port = args.port if args.port else env_int("PORT", 8080)
        self.bind = args.bind if args.bind else env("BIND_ADDRESS", "0.0.0.0")
        self.base_path = env("BASE_PATH").rstrip("/")
        if self.base_path and not self.base_path.startswith("/"):
            self.base_path = "/" + self.base_path
        self.greeting = env("GREETING", "Hello")
        self.allowed_hosts = [h.lower().rstrip(".") for h in env_list("ALLOWED_HOSTS", "*")]
        self.required_env = env_list("REQUIRED_ENV")
        self.config_file = env("CONFIG_FILE")
        self.maintenance_file = env("MAINTENANCE_FILE")
        self.tls_cert, self.tls_key = env("TLS_CERT_FILE"), env("TLS_KEY_FILE")
        # start-up / resources
        self.warmup = env_int("WARMUP_SECONDS", 0)
        self.cache_mb = env_int("CACHE_MB", 0)
        self.cache_warmup = env("CACHE_WARMUP", "eager").lower()
        self.disk_cache_mb = env_int("DISK_CACHE_MB", 0)
        self.work_dir = env("WORK_DIR", "/tmp/labapp")
        self.cache_dir = env("CACHE_DIR") or os.path.join(self.work_dir, "cache")
        self.data_dir = env("DATA_DIR")
        self.worker_threads = env_int("WORKER_THREADS", 16)
        self.indexer_workers = env_int("INDEXER_WORKERS", 0)
        self.hash_iterations = env_int("HASH_ITERATIONS", 0)
        self.max_upload_mb = env_int("MAX_UPLOAD_MB", 64)
        self.error_rate = env_float("ERROR_RATE", 0.0)
        # logging
        self.log_level = env("LOG_LEVEL", "info")
        self.log_format = env("LOG_FORMAT", "text")
        self.log_file = env("LOG_FILE")
        self.access_log = env_bool("ACCESS_LOG", True)
        # shutdown
        self.shutdown_mode = env("SHUTDOWN_MODE", "graceful").lower()
        self.shutdown_delay = env_int("SHUTDOWN_DELAY_SECONDS", 0)
        self.shutdown_timeout = env_int("SHUTDOWN_TIMEOUT_SECONDS", 25)
        # dependencies
        self.storage = env("STORAGE_BACKEND", "memory").lower()
        self.auto_migrate = env_bool("AUTO_MIGRATE", False)
        self.ready_check_deps = env_bool("READY_CHECK_DEPENDENCIES", True)
        self.health_check_deps = env_bool("HEALTH_CHECK_DEPENDENCIES", False)
        self.redis_host = env("REDIS_HOST")
        # parsed only when redis is in use: Kubernetes service links inject
        # REDIS_PORT=tcp://10.96.x.y:6379 into every pod next to a Service named "redis"
        self.redis_port = env_int("REDIS_PORT", 6379) if self.redis_host else 6379
        self.redis_db = env_int("REDIS_DB", 0) if self.redis_host else 0
        self.redis_user = env("REDIS_USERNAME")
        self.upstream_url = env("UPSTREAM_URL")
        self.upstream_host = env("UPSTREAM_HOST")
        self.upstream_timeout = env_float("UPSTREAM_TIMEOUT_SECONDS", 3.0)
        self.upstream_required = env_bool("UPSTREAM_REQUIRED", False)
        self.upstream_ca = env("UPSTREAM_CA_FILE")
        # peers
        self.peer_discovery = env("PEER_DISCOVERY", "none").lower()
        self.peer_service = env("PEER_SERVICE")
        self.peer_selector = env("PEER_SELECTOR") or f"app.kubernetes.io/name={self.name}"
        self.peer_refresh = env_int("PEER_REFRESH_SECONDS", 30)
        self.credentials_secret = env("CREDENTIALS_SECRET")

    def public(self):
        d = {k: v for k, v in vars(self).items()}
        d["version"] = VERSION
        return d


CFG = None


class State:
    shutting_down = False
    migrate_pending = False
    migrate_error = ""
    cache = []
    leak = []
    items = []
    lock = threading.Lock()
    requests = {}
    inflight = 0
    last_peers = None


def database_url():
    raw = secret("DATABASE_URL")
    return raw if raw else None


def redact_url(url):
    m = URL_WITH_USERINFO.match(url)
    if not m:
        return url
    user = m.group(2).split(":", 1)[0]
    return f"{m.group(1)}{user}:***@" + url[m.end():] if ":" in m.group(2) else url


# --------------------------------------------------------------------------- redis (RESP)
class RedisError(Exception):
    pass


def _resp_read(f):
    line = f.readline()
    if not line:
        raise RedisError("connection closed by server")
    kind, rest = line[:1], line[1:].rstrip(b"\r\n")
    if kind == b"+":
        return rest.decode()
    if kind == b"-":
        raise RedisError(rest.decode())
    if kind == b":":
        return int(rest)
    if kind == b"$":
        n = int(rest)
        return None if n < 0 else f.read(n + 2)[:-2].decode()
    if kind == b"*":
        n = int(rest)
        return None if n < 0 else [_resp_read(f) for _ in range(n)]
    raise RedisError(f"unexpected reply {line[:40]!r}")


def redis(*commands):
    """Run one or more commands (tuples) on a fresh connection; returns the last reply."""
    def enc(parts):
        out = f"*{len(parts)}\r\n".encode()
        for p in parts:
            b = str(p).encode()
            out += b"$%d\r\n%s\r\n" % (len(b), b)
        return out

    with socket.create_connection((CFG.redis_host, CFG.redis_port), timeout=2) as s:
        f = s.makefile("rb")
        password = secret("REDIS_PASSWORD")
        if password is not None:
            s.sendall(enc(["AUTH", CFG.redis_user, password] if CFG.redis_user else ["AUTH", password]))
            try:
                _resp_read(f)
            except RedisError as e:
                raise RedisError(f"authentication failed (invalid password?): {e}") from None
        if CFG.redis_db:
            s.sendall(enc(["SELECT", CFG.redis_db]))
            _resp_read(f)
        reply = None
        for cmd in commands:
            s.sendall(enc(cmd))
            reply = _resp_read(f)
        return reply


# --------------------------------------------------------------------------- postgres (wire protocol v3)
class PGError(Exception):
    pass


class PG:
    """Just enough of the PostgreSQL protocol: startup, cleartext/md5/SCRAM-SHA-256 auth,
    simple queries returning text rows."""

    def __init__(self, url, timeout=3.0):
        u = urllib.parse.urlsplit(url)
        if u.scheme not in ("postgres", "postgresql"):
            raise PGError(f"unsupported DATABASE_URL scheme {u.scheme!r} (want postgres://)")
        self.user = urllib.parse.unquote(u.username or "postgres")
        pw = secret("DATABASE_PASSWORD")
        self.password = pw if pw is not None else urllib.parse.unquote(u.password or "")
        self.database = urllib.parse.unquote(u.path.lstrip("/")) or self.user
        self.sock = socket.create_connection((u.hostname or "localhost", u.port or 5432), timeout=timeout)
        self.f = self.sock.makefile("rb")
        self._startup()

    def _send(self, kind, payload):
        self.sock.sendall(kind + struct.pack("!I", len(payload) + 4) + payload)

    def _recv(self):
        head = self.f.read(5)
        if len(head) < 5:
            raise PGError("server closed the connection")
        kind, length = head[:1], struct.unpack("!I", head[1:])[0]
        body = self.f.read(length - 4)
        if kind == b"E":
            fields = dict((p[:1].decode(), p[1:].decode()) for p in body.split(b"\0") if p)
            raise PGError(f"{fields.get('M', 'error')} (SQLSTATE {fields.get('C', '?')})")
        return kind, body

    def _startup(self):
        params = b"".join(k + b"\0" + v.encode() + b"\0" for k, v in (
            (b"user", self.user), (b"database", self.database), (b"application_name", "labapp")))
        payload = struct.pack("!I", 196608) + params + b"\0"
        self.sock.sendall(struct.pack("!I", len(payload) + 4) + payload)
        scram = None
        while True:
            kind, body = self._recv()
            if kind == b"R":
                code = struct.unpack("!I", body[:4])[0]
                if code == 0:
                    continue
                if code == 3:
                    self._send(b"p", self.password.encode() + b"\0")
                elif code == 5:
                    inner = hashlib.md5((self.password + self.user).encode()).hexdigest()
                    outer = hashlib.md5(inner.encode() + body[4:8]).hexdigest()
                    self._send(b"p", b"md5" + outer.encode() + b"\0")
                elif code == 10:
                    scram = self._scram_first(body[4:])
                elif code == 11:
                    self._scram_final(scram, body[4:].decode())
                elif code == 12:
                    pass  # server signature; trust the TCP peer in a lab
                else:
                    raise PGError(f"unsupported authentication method {code}")
            elif kind == b"Z":
                return

    def _scram_first(self, mechs):
        if b"SCRAM-SHA-256" not in mechs.split(b"\0"):
            raise PGError("server offers no SCRAM-SHA-256")
        nonce = base64.b64encode(os.urandom(18)).decode()
        first_bare = f"n=,r={nonce}"
        msg = ("n,," + first_bare).encode()
        self._send(b"p", b"SCRAM-SHA-256\0" + struct.pack("!I", len(msg)) + msg)
        return first_bare

    def _scram_final(self, first_bare, server_first):
        attrs = dict(kv.split("=", 1) for kv in server_first.split(","))
        salted = hashlib.pbkdf2_hmac("sha256", self.password.encode(), base64.b64decode(attrs["s"]), int(attrs["i"]))
        client_key = hmac.new(salted, b"Client Key", "sha256").digest()
        stored_key = hashlib.sha256(client_key).digest()
        without_proof = f"c=biws,r={attrs['r']}"
        auth_msg = f"{first_bare},{server_first},{without_proof}".encode()
        signature = hmac.new(stored_key, auth_msg, "sha256").digest()
        proof = base64.b64encode(bytes(a ^ b for a, b in zip(client_key, signature))).decode()
        self._send(b"p", f"{without_proof},p={proof}".encode())

    def query(self, sql):
        self._send(b"Q", sql.encode() + b"\0")
        cols, rows, error = [], [], None
        while True:
            try:
                kind, body = self._recv()
            except PGError as e:  # keep reading until ReadyForQuery
                error = e
                continue
            if kind == b"T":
                n, pos = struct.unpack("!H", body[:2])[0], 2
                for _ in range(n):
                    end = body.index(b"\0", pos)
                    cols.append(body[pos:end].decode())
                    pos = end + 1 + 18
            elif kind == b"D":
                n, pos, row = struct.unpack("!H", body[:2])[0], 2, []
                for _ in range(n):
                    ln = struct.unpack("!i", body[pos:pos + 4])[0]
                    pos += 4
                    row.append(None if ln < 0 else body[pos:pos + ln].decode())
                    pos += max(ln, 0)
                rows.append(row)
            elif kind == b"Z":
                if error:
                    raise error
                return cols, rows

    def close(self):
        try:
            self._send(b"X", b"")
            self.sock.close()
        except OSError:
            pass


def pg_query(sql):
    url = database_url()
    if not url:
        raise PGError("DATABASE_URL is not set")
    db = PG(url)
    try:
        return db.query(sql)
    finally:
        db.close()


def sql_str(s):
    return "'" + str(s).replace("'", "''") + "'"


# --------------------------------------------------------------------------- storage backends
SEED = [("espresso", "2.50"), ("cappuccino", "3.20"), ("croissant", "2.10"), ("bagel", "1.80")]
MIGRATIONS = [
    ("001_create_items", "CREATE TABLE IF NOT EXISTS items (id serial PRIMARY KEY, name text NOT NULL,"
                         " price numeric(8,2) NOT NULL)"),
    ("002_seed_items", "INSERT INTO items (name, price) SELECT * FROM (VALUES "
                       + ",".join(f"({sql_str(n)}, {p})" for n, p in SEED)
                       + ") AS v(name, price) WHERE NOT EXISTS (SELECT 1 FROM items)"),
]


def migrate(verbose=print):
    if CFG.storage == "postgres" or (CFG.storage != "redis" and database_url()):
        db = PG(database_url())
        try:
            db.query("CREATE TABLE IF NOT EXISTS schema_migrations (version text PRIMARY KEY,"
                     " applied_at timestamptz NOT NULL DEFAULT now())")
            for version, sql in MIGRATIONS:
                _, done = db.query(f"SELECT 1 FROM schema_migrations WHERE version = {sql_str(version)}")
                if done:
                    verbose(f"migration {version}: already applied")
                    continue
                verbose(f"migration {version}: applying")
                db.query(sql)
                db.query(f"INSERT INTO schema_migrations (version) VALUES ({sql_str(version)})")
        finally:
            db.close()
    elif CFG.storage == "redis":
        if not redis(("EXISTS", "labapp:items")):
            redis(*[("RPUSH", "labapp:items", json.dumps({"id": i + 1, "name": n, "price": p}))
                    for i, (n, p) in enumerate(SEED)])
            verbose("seeded redis list labapp:items")
        else:
            verbose("redis list labapp:items already seeded")
    else:
        verbose("STORAGE_BACKEND=memory: nothing to migrate")


def items_list():
    if CFG.storage == "postgres":
        _, rows = pg_query("SELECT id, name, price FROM items ORDER BY id")
        return [{"id": int(r[0]), "name": r[1], "price": r[2]} for r in rows]
    if CFG.storage == "redis":
        if not redis(("EXISTS", "labapp:items")):
            migrate(verbose=lambda m: log("info", m))
        return [json.loads(x) for x in redis(("LRANGE", "labapp:items", 0, -1)) or []]
    return list(State.items)


def items_add(name, price):
    if CFG.storage == "postgres":
        _, rows = pg_query(f"INSERT INTO items (name, price) VALUES ({sql_str(name)}, {float(price)}) RETURNING id")
        return {"id": int(rows[0][0]), "name": name, "price": f"{float(price):.2f}"}
    if CFG.storage == "redis":
        n = redis(("LLEN", "labapp:items"))
        item = {"id": n + 1, "name": name, "price": f"{float(price):.2f}"}
        redis(("RPUSH", "labapp:items", json.dumps(item)))
        return item
    with State.lock:
        item = {"id": len(State.items) + 1, "name": name, "price": f"{float(price):.2f}"}
        State.items.append(item)
    return item


def auto_migrate_loop():
    while True:
        try:
            migrate(verbose=lambda m: log("info", m))
            State.migrate_pending, State.migrate_error = False, ""
            log("info", "schema is up to date")
            return
        except Exception as e:  # noqa: BLE001
            State.migrate_error = str(e)
            log("warn", f"auto-migrate failed, retrying in 5s: {e}")
            time.sleep(5)


# --------------------------------------------------------------------------- upstream / kubernetes API
def call_upstream(path_override=None):
    """GET UPSTREAM_URL with the bearer token. Returns (status, body_snippet, ms)."""
    url = path_override or CFG.upstream_url
    req = urllib.request.Request(url, headers={"User-Agent": f"labapp/{VERSION}"})
    token = secret("UPSTREAM_TOKEN")
    if token is not None:
        req.add_header("Authorization", f"Bearer {token}")
    if CFG.upstream_host:
        req.add_header("Host", CFG.upstream_host)
    ctx = ssl.create_default_context(cafile=CFG.upstream_ca or None) if url.startswith("https") else None
    t0 = time.monotonic()
    try:
        with urllib.request.urlopen(req, timeout=CFG.upstream_timeout, context=ctx) as r:
            body = r.read(4096)
            return r.status, body.decode(errors="replace"), int((time.monotonic() - t0) * 1000)
    except urllib.error.HTTPError as e:
        return e.code, e.read(512).decode(errors="replace"), int((time.monotonic() - t0) * 1000)
    except ValueError as e:
        if "header" in str(e).lower():
            raise RuntimeError("Invalid return character or leading space in header: Authorization") from None
        raise


def k8s_get(path):
    """GET from the API server with the in-cluster config, failing the way client-go does."""
    host, port = env("KUBERNETES_SERVICE_HOST"), env("KUBERNETES_SERVICE_PORT")
    if not host or not port:
        raise RuntimeError("unable to load in-cluster configuration, KUBERNETES_SERVICE_HOST and "
                           "KUBERNETES_SERVICE_PORT must be defined")
    if ":" in host:
        host = f"[{host}]"
    req = urllib.request.Request(f"https://{host}:{port}{path}", headers={"Accept": "application/json"})
    token_file = os.path.join(SA_DIR, "token")
    try:
        with open(token_file) as f:  # re-read every call: projected tokens rotate
            req.add_header("Authorization", "Bearer " + f.read().strip())
    except OSError as e:
        raise RuntimeError(f"unable to load in-cluster configuration: open {token_file}: "
                           f"{e.strerror.lower()}") from None
    ca = os.path.join(SA_DIR, "ca.crt")
    ctx = ssl.create_default_context(cafile=ca if os.path.exists(ca) else None)
    try:
        with urllib.request.urlopen(req, timeout=5, context=ctx) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        try:
            msg = json.load(e).get("message", "")
        except Exception:  # noqa: BLE001
            msg = ""
        raise RuntimeError(f"{e.code} {e.reason}: {msg}".rstrip(": ")) from None


def pod_namespace():
    ns = env("POD_NAMESPACE")
    if ns:
        return ns
    try:
        with open(os.path.join(SA_DIR, "namespace")) as f:
            return f.read().strip()
    except OSError:
        return "default"


def discover_peers():
    mode = CFG.peer_discovery
    if mode == "dns":
        if not CFG.peer_service:
            raise RuntimeError("PEER_DISCOVERY=dns needs PEER_SERVICE")
        infos = socket.getaddrinfo(CFG.peer_service, CFG.port, socket.AF_INET, socket.SOCK_STREAM)
        return [{"ip": ip} for ip in sorted({i[4][0] for i in infos}, key=socket.inet_aton)]
    if mode == "kubernetes":
        sel = urllib.parse.quote(CFG.peer_selector)
        data = k8s_get(f"/api/v1/namespaces/{pod_namespace()}/pods?labelSelector={sel}")
        peers = []
        for p in data.get("items", []):
            st = p.get("status", {})
            ready = any(c.get("type") == "Ready" and c.get("status") == "True" for c in st.get("conditions", []))
            if st.get("podIP"):
                peers.append({"pod": p["metadata"]["name"], "ip": st["podIP"], "ready": ready})
        return sorted(peers, key=lambda x: x["pod"])
    raise RuntimeError(f"peer discovery disabled (PEER_DISCOVERY={mode})")


def peer_watch_loop():
    while not State.shutting_down:
        try:
            peers = [p["ip"] for p in discover_peers()]
            if peers != State.last_peers:
                log("info", f"peers ({len(peers)}): {' '.join(peers) or '-'}")
                State.last_peers = peers
        except Exception as e:  # noqa: BLE001
            log("error", f"peer discovery failed: {e}")
            State.last_peers = None
        time.sleep(max(CFG.peer_refresh, 5))


# --------------------------------------------------------------------------- health
def dependency_checks(checks):
    good = True
    if CFG.credentials_secret:
        try:
            ref, data = credentials()
            checks["credentials"] = f"ok ({len(data)} keys from secret {ref})"
        except Exception as e:  # noqa: BLE001
            checks["credentials"] = f"error: {e}"
            good = False
    if CFG.redis_host:
        try:
            redis(("PING",))
            checks["redis"] = "ok"
        except Exception as e:  # noqa: BLE001
            checks["redis"] = f"error: {e}"
            good = False
    if database_url():
        try:
            pg_query("SELECT 1")
            checks["postgres"] = "ok"
        except Exception as e:  # noqa: BLE001
            checks["postgres"] = f"error: {e}"
            good = False
    if CFG.upstream_url and CFG.upstream_required:
        try:
            code, body, _ = call_upstream()
            checks["upstream"] = "ok" if code < 400 else f"error: HTTP {code} {body.strip()[:120]}"
            good &= code < 400
        except Exception as e:  # noqa: BLE001
            checks["upstream"] = f"error: {getattr(e, 'reason', e)}"
            good = False
    if CFG.data_dir:
        try:
            probe = os.path.join(CFG.data_dir, f".probe-{HOSTNAME}")
            with open(probe, "w") as f:
                f.write("ok")
            os.remove(probe)
            checks["data_dir"] = "ok"
        except OSError as e:
            checks["data_dir"] = f"error: {e}"
            good = False
    return good


def readiness():
    checks, ok = {}, True
    if State.shutting_down:
        checks["shutdown"] = "in progress"
        ok = False
    if CFG.maintenance_file and os.path.exists(CFG.maintenance_file):
        checks["maintenance"] = f"on ({CFG.maintenance_file} exists)"
        ok = False
    if State.migrate_pending:
        checks["schema"] = f"pending: {State.migrate_error or 'migrating'}"
        ok = False
    if CFG.ready_check_deps:
        ok = dependency_checks(checks) and ok
    return ok, checks


def read_config_file():
    path = CFG.config_file
    if not path:
        return None
    out = {"path": path}
    try:
        st = os.stat(path)
        with open(path) as f:
            text = f.read()
    except OSError as e:
        out["error"] = str(e)
        return out
    out["modified"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(st.st_mtime))
    values = {}
    if text.lstrip().startswith("{"):
        try:
            values = json.loads(text)
        except ValueError as e:
            out["error"] = f"invalid JSON: {e}"
    else:
        for line in text.splitlines():
            line = line.strip()
            if line and not line.startswith(("#", ";", "[")) and ("=" in line or ":" in line):
                k, v = re.split(r"\s*[=:]\s*", line, maxsplit=1)
                values[k.strip()] = v.strip().strip('"')
    out["values"] = {k: ("<set>" if SECRET_NAME.search(k) else v) for k, v in values.items()}
    out["_raw"] = values
    return out


def current_greeting():
    cf = read_config_file()
    if cf and "greeting" in cf.get("_raw", {}):
        return str(cf["_raw"]["greeting"])
    return CFG.greeting


def masked_env(show_links=False):
    out = {}
    for k in sorted(os.environ):
        v = os.environ[k]
        if not show_links and SERVICE_LINK.match(k):
            continue
        if k.endswith("_FILE"):
            out[k] = v
        elif SECRET_NAME.search(k):
            out[k] = "<set>" if v else "<empty>"
        else:
            out[k] = redact_url(v)
    return out


# --------------------------------------------------------------------------- load helpers
def burn_cpu(ms):
    end = time.perf_counter() + ms / 1000.0
    n = 0
    while time.perf_counter() < end:
        hashlib.pbkdf2_hmac("sha256", b"labapp", b"burn", 2000)  # releases the GIL
        n += 1
    return n


def indexer_loop(i):
    log("info", f"search indexer {i} started")
    while True:
        hashlib.pbkdf2_hmac("sha256", b"index", b"%d" % i, 50000)


def grow_cache():
    """CACHE_WARMUP=lazy: every business request adds 4 MiB until CACHE_MB is cached."""
    with State.lock:
        have = len(State.cache) * 4
        if have < CFG.cache_mb:
            State.cache.append(b"c" * (4 * MIB))


def fill_disk_cache():
    try:
        os.makedirs(CFG.cache_dir, exist_ok=True)
        blob = os.urandom(MIB)
        for i in range(CFG.disk_cache_mb):
            with open(os.path.join(CFG.cache_dir, f"blob-{i:05d}.bin"), "wb") as f:
                f.write(blob)
            if (i + 1) % 50 == 0:
                log("info", f"disk cache: {i + 1}/{CFG.disk_cache_mb} MiB written to {CFG.cache_dir}")
        log("info", f"disk cache ready: {CFG.disk_cache_mb} MiB in {CFG.cache_dir}")
    except OSError as e:
        log("error", f"disk cache: {e}")


# --------------------------------------------------------------------------- HTTP
OPS = {"/health", "/ready", "/metrics"}  # served at / regardless of BASE_PATH / ALLOWED_HOSTS
OPEN = OPS | {"/version", "/env", "/config", "/peers"}  # never need AUTH_TOKEN


def host_allowed(host):
    host = host.strip().lower()
    if host.startswith("["):
        host = host[1:host.find("]")]
    elif host.count(":") == 1:
        host = host.split(":", 1)[0]
    host = host.rstrip(".")
    for pat in CFG.allowed_hosts:
        if pat == "*" or host == pat or (pat.startswith(".") and (host == pat[1:] or host.endswith(pat))):
            return True
    return False


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = f"labapp/{VERSION}"
    sys_version = ""
    timeout = 30

    def log_message(self, fmt, *args):  # replaced by our access log
        pass

    def log_request(self, code="-", size="-"):
        self._status = int(code) if str(code).isdigit() else 0

    # ---- plumbing
    def send(self, code, body, ctype=None, headers=None):
        if isinstance(body, (dict, list)):
            data, ctype = (json.dumps(body, indent=2) + "\n").encode(), ctype or "application/json"
        else:
            data = body if isinstance(body, bytes) else str(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype or "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Connection", "close")
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)
        self.close_connection = True

    def body(self, limit):
        if "chunked" in self.headers.get("Transfer-Encoding", "").lower():
            out = bytearray()
            while True:
                size = int(self.rfile.readline().split(b";")[0].strip() or b"0", 16)
                if size == 0:
                    self.rfile.readline()
                    return bytes(out)
                if len(out) + size > limit:
                    raise OverflowError
                out += self.rfile.read(size)
                self.rfile.readline()
        length = int(self.headers.get("Content-Length") or 0)
        if length > limit:
            raise OverflowError
        return self.rfile.read(length)

    def do_GET(self):  # noqa: N802
        self._status, t0 = 0, time.monotonic()
        with State.lock:
            State.inflight += 1
        try:
            self.route()
        except (BrokenPipeError, ConnectionResetError, socket.timeout):
            pass
        except Exception as e:  # noqa: BLE001
            log("error", f"unhandled error on {self.command} {self.path}: {e}")
            log("debug", traceback.format_exc())
            try:
                self.send(500, f"internal error: {e}\n")
            except OSError:
                pass
        finally:
            with State.lock:
                State.inflight -= 1
                State.requests[self._status] = State.requests.get(self._status, 0) + 1
            if CFG.access_log:
                path = self.path.split("?", 1)[0]
                level = "debug" if path in OPS else "info"
                log(level, f"{self.command} {self.path} {self._status}",
                    ms=f"{(time.monotonic() - t0) * 1000:.1f}", client=self.client_address[0])

    do_POST = do_PUT = do_DELETE = do_HEAD = do_GET

    def route(self):
        url = urllib.parse.urlsplit(self.path)
        path, q = url.path or "/", urllib.parse.parse_qs(url.query)
        if path in OPS:
            return {"/health": self.h_health, "/ready": self.h_ready, "/metrics": self.h_metrics}[path](q)
        host = self.headers.get("Host", "")
        if not host_allowed(host):
            log("warn", f"rejected request for unknown virtual host {host!r}")
            return self.send(404, f"404 page not found: no such virtual host {host!r}\n")
        if CFG.base_path:
            if path != CFG.base_path and not path.startswith(CFG.base_path + "/"):
                return self.send(404, "404 page not found\n")
            path = path[len(CFG.base_path):] or "/"
        if path not in OPEN:
            token = secret("AUTH_TOKEN")
            if token is not None:
                got = self.headers.get("Authorization", "")
                if not got.startswith("Bearer "):
                    return self.send(401, "missing bearer token\n", headers={"WWW-Authenticate": "Bearer"})
                if not hmac.compare_digest(got[7:].encode(), token.encode()):
                    log("warn", "rejected request with an invalid bearer token", client=self.client_address[0])
                    return self.send(401, "invalid token\n", headers={"WWW-Authenticate": 'Bearer error="invalid_token"'})
        routes = {"/": self.h_root, "/version": self.h_version, "/env": self.h_env, "/config": self.h_config,
                  "/peers": self.h_peers, "/items": self.h_items, "/upstream": self.h_upstream,
                  "/burn": self.h_burn, "/alloc": self.h_alloc, "/big": self.h_big, "/slow": self.h_slow,
                  "/upload": self.h_upload, "/admin/crash": self.h_crash}
        if path in routes:
            return routes[path](q)
        if path.startswith("/status/"):
            return self.h_status(path[8:])
        if path == "/kv" or path.startswith("/kv/"):
            return self.h_kv(path[4:])
        return self.send(404, "404 page not found\n")

    def business(self):
        if CFG.cache_mb and CFG.cache_warmup == "lazy":
            grow_cache()
        if CFG.hash_iterations:
            hashlib.pbkdf2_hmac("sha256", HOSTNAME.encode(), b"session", CFG.hash_iterations)

    # ---- ops
    def h_health(self, q):
        if CFG.health_check_deps:
            checks = {}
            if not dependency_checks(checks):
                log("warn", "liveness check failed: " + json.dumps(checks))
                return self.send(503, {"status": "unhealthy", "checks": checks})
        return self.send(200, "ok\n")

    def h_ready(self, q):
        ok, checks = readiness()
        if not ok:
            log("warn", "not ready: " + "; ".join(f"{k}: {v}" for k, v in checks.items() if v != "ok"))
        return self.send(200 if ok else 503, {"status": "ready" if ok else "not ready", "checks": checks})

    def h_metrics(self, q):
        lines = ["# TYPE labapp_requests_total counter"]
        with State.lock:
            for code, n in sorted(State.requests.items()):
                lines.append(f'labapp_requests_total{{code="{code}"}} {n}')
            inflight = State.inflight
        lines += [f"labapp_inflight_requests {inflight}",
                  f"labapp_uptime_seconds {time.time() - STARTED:.0f}",
                  f"labapp_cache_bytes {sum(map(len, State.cache)) + sum(map(len, State.leak))}",
                  f'labapp_info{{version="{VERSION}",name="{CFG.name}"}} 1']
        return self.send(200, "\n".join(lines) + "\n", "text/plain; version=0.0.4")

    # ---- introspection
    def h_version(self, q):
        return self.send(200, {"name": CFG.name, "version": VERSION, "hostname": HOSTNAME,
                               "pod_ip": env("POD_IP") or None, "node": env("NODE_NAME") or None,
                               "uptime_seconds": int(time.time() - STARTED)})

    def h_env(self, q):
        return self.send(200, masked_env(show_links=bool(q.get("all"))))

    def h_config(self, q):
        cf = read_config_file()
        if cf:
            cf.pop("_raw", None)
        secrets = {k: secret_presence(k) for k in
                   ("DATABASE_URL", "DATABASE_PASSWORD", "REDIS_PASSWORD", "UPSTREAM_TOKEN", "AUTH_TOKEN")}
        if CFG.credentials_secret:
            secrets["CREDENTIALS_SECRET"] = CFG.credentials_secret
        url = database_url()
        return self.send(200, {"settings": CFG.public(),
                               "secrets": {k: v for k, v in secrets.items() if v is not None},
                               "database": redact_url(url) if url else None,
                               "config_file": cf, "greeting": current_greeting()})

    def h_peers(self, q):
        try:
            peers = discover_peers()
        except Exception as e:  # noqa: BLE001
            log("error", f"peer discovery failed: {e}")
            return self.send(502, {"discovery": CFG.peer_discovery, "error": str(e)})
        if q.get("probe"):
            for p in peers:
                try:
                    with urllib.request.urlopen(f"http://{p['ip']}:{CFG.port}/version", timeout=2) as r:
                        p["hostname"] = json.load(r).get("hostname")
                except Exception as e:  # noqa: BLE001
                    p["error"] = str(getattr(e, "reason", e))
        return self.send(200, {"discovery": CFG.peer_discovery,
                               "service": CFG.peer_service if CFG.peer_discovery == "dns" else None,
                               "selector": CFG.peer_selector if CFG.peer_discovery == "kubernetes" else None,
                               "count": len(peers), "peers": peers})

    # ---- business
    def h_root(self, q):
        self.business()
        msg = f"{current_greeting()} from {HOSTNAME} ({CFG.name} v{VERSION})"
        if CFG.redis_host:
            try:
                msg += f" hits={redis(('INCR', 'labapp:hits'))}"
            except Exception as e:  # noqa: BLE001
                log("error", f"redis: {e}")
                return self.send(502, f"{msg} - redis error: {e}\n")
        if CFG.upstream_url:
            try:
                code, body, ms = call_upstream()
            except Exception as e:  # noqa: BLE001
                reason = getattr(e, "reason", e)
                log("error", f"upstream {CFG.upstream_url}: {reason}")
                return self.send(502, f"{msg} - upstream error: {reason}\n")
            if code >= 400:
                log("error", f"upstream {CFG.upstream_url} returned HTTP {code}: {body.strip()[:200]}")
                return self.send(502, f"{msg} - upstream returned HTTP {code}\n")
            msg += f" upstream={code} ({ms}ms)"
        return self.send(200, msg + "\n")

    def h_items(self, q):
        self.business()
        try:
            if self.command == "POST":
                data = json.loads(self.body(MIB) or b"{}")
                return self.send(201, items_add(data.get("name", "unnamed"), data.get("price", 0)))
            if CFG.error_rate and random.random() < CFG.error_rate:
                log("error", "GET /items failed: upstream pricing service timeout")
                return self.send(500, {"error": "pricing service timeout"})
            items = items_list()
        except Exception as e:  # noqa: BLE001
            log("error", f"{CFG.storage} backend: {e}")
            return self.send(500 if CFG.storage == "postgres" else 502, {"error": f"{CFG.storage}: {e}"})
        out = {"served_by": HOSTNAME, "app": CFG.name, "version": VERSION, "source": CFG.storage,
               "count": len(items), "items": items}
        if CFG.redis_host and CFG.storage != "redis":
            try:
                out["views"] = redis(("INCR", "labapp:views"))
            except Exception as e:  # noqa: BLE001
                log("warn", f"redis views counter: {e}")
        return self.send(200, out)

    def h_upstream(self, q):
        if not CFG.upstream_url:
            return self.send(404, "UPSTREAM_URL is not set\n")
        try:
            code, body, ms = call_upstream()
        except Exception as e:  # noqa: BLE001
            reason = str(getattr(e, "reason", e))
            log("error", f"upstream {CFG.upstream_url}: {reason}")
            return self.send(502, {"upstream": CFG.upstream_url, "error": reason})
        if code >= 400:
            log("error", f"upstream {CFG.upstream_url} returned HTTP {code}: {body.strip()[:200]}")
        return self.send(200 if code < 400 else 502,
                         {"upstream": CFG.upstream_url, "status": code, "ms": ms, "body": body[:1000]})

    # ---- load / fault helpers
    def h_burn(self, q):
        ms = min(int(q.get("ms", ["200"])[0]), 60000)
        t0 = time.monotonic()
        rounds = burn_cpu(ms)
        return self.send(200, {"burned_ms": int((time.monotonic() - t0) * 1000), "rounds": rounds, "host": HOSTNAME})

    def h_alloc(self, q):
        if q.get("free"):
            State.leak.clear()
        mb = int(q.get("mb", ["0"])[0])
        for _ in range(mb // 8):
            State.leak.append(b"a" * (8 * MIB))
        if mb % 8:
            State.leak.append(b"a" * ((mb % 8) * MIB))
        return self.send(200, {"retained_mb": sum(map(len, State.leak)) // MIB, "host": HOSTNAME})

    def h_big(self, q):
        kb = int(q["kb"][0]) if "kb" in q else int(q.get("mb", ["1"])[0]) * 1024
        size = min(max(kb, 0), 2048 * 1024) * 1024
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(size))
        self.send_header("Connection", "close")
        self.end_headers()
        chunk = b"z" * 65536
        left = size if self.command != "HEAD" else 0
        while left > 0:
            self.wfile.write(chunk[:min(left, 65536)])
            left -= 65536
        self.close_connection = True

    def h_slow(self, q):
        ms = min(int(q.get("ms", ["1000"])[0]), 600000)
        time.sleep(ms / 1000.0)
        return self.send(200, f"slept {ms}ms on {HOSTNAME}\n")

    def h_status(self, code):
        try:
            code = int(code)
            assert 200 <= code <= 599
        except (ValueError, AssertionError):
            return self.send(400, "want /status/<200-599>\n")
        return self.send(code, f"status {code} from {HOSTNAME}\n")

    def h_upload(self, q):
        if self.command not in ("POST", "PUT"):
            return self.send(405, "use POST or PUT\n", headers={"Allow": "POST, PUT"})
        try:
            data = self.body(CFG.max_upload_mb * MIB)
        except OverflowError:
            return self.send(413, f"upload larger than MAX_UPLOAD_MB={CFG.max_upload_mb}\n")
        return self.send(200, {"received_bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
                               "host": HOSTNAME})

    def h_kv(self, key):
        key = key.lstrip("/")
        if not CFG.data_dir:
            return self.send(503, "DATA_DIR is not set - no persistent storage configured\n")
        base = os.path.join(CFG.data_dir, "kv")
        if not key:
            try:
                return self.send(200, {"keys": sorted(os.listdir(base)), "host": HOSTNAME})
            except FileNotFoundError:
                return self.send(200, {"keys": [], "host": HOSTNAME})
        if not re.fullmatch(r"[A-Za-z0-9._-]{1,128}", key) or key.startswith("."):
            return self.send(400, "bad key\n")
        path = os.path.join(base, key)
        try:
            if self.command in ("PUT", "POST"):
                os.makedirs(base, exist_ok=True)
                data = self.body(MIB)
                tmp = f"{path}.tmp-{HOSTNAME}"
                with open(tmp, "wb") as f:
                    f.write(data)
                os.replace(tmp, path)
                return self.send(201, {"key": key, "bytes": len(data), "host": HOSTNAME})
            if self.command == "DELETE":
                os.remove(path)
                return self.send(200, {"deleted": key})
            with open(path, "rb") as f:
                return self.send(200, f.read(), "application/octet-stream")
        except FileNotFoundError:
            return self.send(404, f"no such key {key}\n")
        except OverflowError:
            return self.send(413, "value larger than 1 MiB\n")
        except OSError as e:
            log("error", f"kv {key}: {e}")
            return self.send(500, f"storage error: {e}\n")

    def h_crash(self, q):
        code = int(q.get("code", ["1"])[0])
        msg = q.get("msg", ["unrecoverable internal error"])[0]
        self.send(202, f"crashing with exit code {code}\n")
        threading.Timer(0.2, fatal, args=(msg, code)).start()


class PoolServer(socketserver.TCPServer):
    """TCP server with a fixed, pre-started pool of WORKER_THREADS request threads."""
    allow_reuse_address = True
    request_queue_size = 128

    def __init__(self, addr, handler, workers, tls=None):
        self.address_family = socket.AF_INET6 if ":" in addr[0] else socket.AF_INET
        self.jobs = queue.Queue()
        self.busy = 0
        self.busy_lock = threading.Lock()
        self.tls = tls
        for i in range(workers):  # RuntimeError "can't start new thread" under a low pids limit
            threading.Thread(target=self._worker, name=f"worker-{i}", daemon=True).start()
        super().__init__(addr, handler)

    def server_bind(self):
        if self.address_family == socket.AF_INET6:
            self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        super().server_bind()
        if self.tls:
            self.socket = self.tls.wrap_socket(self.socket, server_side=True, do_handshake_on_connect=False)

    def process_request(self, request, client_address):
        self.jobs.put((request, client_address))

    def _worker(self):
        while True:
            request, addr = self.jobs.get()
            with self.busy_lock:
                self.busy += 1
            try:
                if isinstance(request, ssl.SSLSocket):
                    request.settimeout(10)
                    request.do_handshake()
                self.finish_request(request, addr)
            except Exception as e:  # noqa: BLE001
                if not isinstance(e, (ssl.SSLError, OSError)):
                    log("error", f"worker error: {e}")
            finally:
                self.shutdown_request(request)
                with self.busy_lock:
                    self.busy -= 1


SERVER = None


def on_signal(signum, frame):
    name = signal.Signals(signum).name
    if CFG.shutdown_mode == "ignore":
        log("warn", f"{name} received - ignored (SHUTDOWN_MODE=ignore)")
        return
    if CFG.shutdown_mode == "immediate":
        log("info", f"{name} received - exiting now, {State.inflight} requests in flight are dropped")
        os._exit(0)
    if State.shutting_down:
        return
    State.shutting_down = True
    log("info", f"{name} received - graceful shutdown: keep serving {CFG.shutdown_delay}s, then drain "
                f"up to {CFG.shutdown_timeout}s ({State.inflight} in flight)")

    def stop():
        if SERVER is None:  # still warming up: nothing to drain
            os._exit(0)
        time.sleep(CFG.shutdown_delay)
        SERVER.shutdown()

    threading.Thread(target=stop, daemon=True).start()


def cmd_serve(args):
    global CFG, SERVER
    CFG = Settings(args)
    try:
        LOG.setup(CFG.log_level, CFG.log_format, CFG.log_file)
    except OSError as e:
        fatal(f"cannot open LOG_FILE {CFG.log_file}: {e}")

    for name in CFG.required_env:
        if not os.environ.get(name) and not os.environ.get(name + "_FILE"):
            fatal(f"required setting {name} is not set")
    if CFG.storage == "postgres" and not database_url():
        fatal("STORAGE_BACKEND=postgres requires DATABASE_URL")
    if CFG.storage == "redis" and not CFG.redis_host:
        fatal("STORAGE_BACKEND=redis requires REDIS_HOST")
    if CFG.storage not in ("memory", "redis", "postgres"):
        fatal(f"unknown STORAGE_BACKEND {CFG.storage!r} (memory, redis, postgres)")
    if CFG.shutdown_mode not in ("graceful", "immediate", "ignore"):
        fatal(f"unknown SHUTDOWN_MODE {CFG.shutdown_mode!r} (graceful, immediate, ignore)")
    if CFG.peer_discovery not in ("none", "dns", "kubernetes"):
        fatal(f"unknown PEER_DISCOVERY {CFG.peer_discovery!r} (none, dns, kubernetes)")
    try:
        os.makedirs(CFG.work_dir, exist_ok=True)
        with open(os.path.join(CFG.work_dir, "labapp.pid"), "w") as f:
            f.write(f"{os.getpid()}\n")
    except OSError as e:
        fatal(f"cannot initialise work dir {CFG.work_dir}: {e}")
    if CFG.data_dir:
        try:
            os.makedirs(CFG.data_dir, exist_ok=True)
            with open(os.path.join(CFG.data_dir, ".write-test"), "w") as f:
                f.write(HOSTNAME)
        except OSError as e:
            fatal(f"cannot write to DATA_DIR {CFG.data_dir}: {e}")

    State.items = [{"id": i + 1, "name": n, "price": p} for i, (n, p) in enumerate(SEED)]
    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)
    log("info", f"starting {CFG.name} v{VERSION} (pid {os.getpid()}, storage {CFG.storage})")

    if CFG.cache_mb and CFG.cache_warmup != "lazy":
        log("info", f"warming up in-memory cache: {CFG.cache_mb} MiB")
        for _ in range(0, CFG.cache_mb, 4):
            State.cache.append(b"c" * (4 * MIB))
        log("info", "cache ready")
    if CFG.warmup:
        log("info", f"loading dataset, this takes {CFG.warmup}s")
        for i in range(CFG.warmup):
            time.sleep(1)
            if (i + 1) % 10 == 0 and i + 1 < CFG.warmup:
                log("info", f"loading dataset: {i + 1}/{CFG.warmup}s")
        log("info", "dataset loaded")

    tls = None
    if CFG.tls_cert:
        try:
            tls = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            tls.load_cert_chain(CFG.tls_cert, CFG.tls_key or None)
        except (OSError, ssl.SSLError) as e:
            fatal(f"cannot load TLS_CERT_FILE/TLS_KEY_FILE: {e}")
    try:
        SERVER = PoolServer((CFG.bind, CFG.port), Handler, CFG.worker_threads, tls)
    except RuntimeError as e:
        fatal(f"cannot start {CFG.worker_threads} worker threads: {e}")
    except OSError as e:
        fatal(f"cannot listen on {CFG.bind}:{CFG.port}: {e}")

    def background(target, *a):
        try:
            threading.Thread(target=target, args=a, daemon=True).start()
        except RuntimeError as e:
            fatal(f"cannot start background thread: {e}")

    if CFG.auto_migrate and (CFG.storage != "memory"):
        State.migrate_pending = True
        background(auto_migrate_loop)
    if CFG.disk_cache_mb:
        background(fill_disk_cache)
    for i in range(CFG.indexer_workers):
        background(indexer_loop, i)
    if CFG.peer_discovery != "none":
        background(peer_watch_loop)
    if CFG.credentials_secret:
        try:
            ref, data = credentials()
            log("info", f"loaded {len(data)} credentials from secret {ref}")
        except Exception:  # noqa: BLE001 - already logged
            pass
    if CFG.redis_host:
        try:
            redis(("PING",))
            log("info", f"connected to redis {CFG.redis_host}:{CFG.redis_port}")
        except Exception as e:  # noqa: BLE001
            log("warn", f"redis {CFG.redis_host}:{CFG.redis_port} not usable yet: {e}")
    if database_url() and not CFG.auto_migrate:
        try:
            pg_query("SELECT 1")
            log("info", f"connected to {redact_url(database_url())}")
        except Exception as e:  # noqa: BLE001
            log("warn", f"database not usable yet: {e}")

    scheme = "https" if tls else "http"
    log("info", f"listening on {scheme}://{CFG.bind}:{CFG.port}{CFG.base_path or ''} "
                f"({CFG.worker_threads} workers)")
    SERVER.serve_forever(poll_interval=0.2)

    SERVER.server_close()
    deadline = time.monotonic() + CFG.shutdown_timeout
    while (SERVER.busy or not SERVER.jobs.empty()) and time.monotonic() < deadline:
        time.sleep(0.1)
    if SERVER.busy:
        log("warn", f"shutdown timeout reached, dropping {SERVER.busy} requests")
    log("info", "shutdown complete")
    sys.stdout.flush()
    os._exit(0)


# --------------------------------------------------------------------------- other subcommands
def plain_exit(*_):
    os._exit(0)


def cmd_migrate(args):
    global CFG
    CFG = Settings(argparse.Namespace(port=None, bind=None))
    deadline = time.monotonic() + env_int("MIGRATE_TIMEOUT_SECONDS", 60)
    print(f"labapp {VERSION}: running migrations (storage {CFG.storage})", flush=True)
    while True:
        try:
            migrate(verbose=lambda m: print(m, flush=True))
            break
        except Exception as e:  # noqa: BLE001
            if time.monotonic() > deadline:
                print(f"migration failed: {e}", file=sys.stderr, flush=True)
                return 1
            print(f"database not ready ({e}), retrying in 3s", flush=True)
            time.sleep(3)
    time.sleep(env_int("MIGRATE_SECONDS", 0))
    print("migrations complete - done", flush=True)
    return 0


def cmd_read_secret(args):
    """Read a Secret through the API with the pod's ServiceAccount; print key names only."""
    ns, _, name = args.secret.rpartition("/")
    ns = ns or pod_namespace()
    try:
        obj = k8s_get(f"/api/v1/namespaces/{ns}/secrets/{name}")
    except Exception as e:  # noqa: BLE001
        print(f"cannot read secret {ns}/{name}: {e}", file=sys.stderr, flush=True)
        return 1
    keys = sorted((obj.get("data") or {}).keys())
    print(f"secret {ns}/{name}: {len(keys)} keys: {', '.join(keys) or '-'}", flush=True)
    return 0


def cmd_get(args):
    data = args.data.encode() if args.data is not None else None
    req = urllib.request.Request(args.url, data=data, method=args.method or ("POST" if data else "GET"))
    for h in args.header:
        k, _, v = h.partition(":")
        req.add_header(k.strip(), v.strip())
    ctx = None
    if args.url.startswith("https"):
        ctx = ssl.create_default_context(cafile=args.cacert)
        if args.insecure:
            ctx.check_hostname, ctx.verify_mode = False, ssl.CERT_NONE
    try:
        with urllib.request.urlopen(req, timeout=args.timeout, context=ctx) as r:
            code, body = r.status, r.read()
    except urllib.error.HTTPError as e:
        code, body = e.code, e.read()
    except Exception as e:  # noqa: BLE001
        print(f"labapp get {args.url}: {getattr(e, 'reason', e)}", file=sys.stderr)
        return 2
    if not args.quiet:
        sys.stdout.buffer.write(body)
        sys.stdout.flush()
    if args.verbose:
        print(f"HTTP {code}", file=sys.stderr)
    ok = code == args.expect if args.expect else 200 <= code < 400
    return 0 if ok else 1


def cmd_load(args):
    stop_at = time.monotonic() + args.duration
    lock, lat, codes = threading.Lock(), [], {}
    per_worker = (args.concurrency / args.rps) if args.rps else 0

    def worker():
        while time.monotonic() < stop_at:
            t0 = time.monotonic()
            try:
                with urllib.request.urlopen(args.url, timeout=args.timeout) as r:
                    r.read()
                    code = str(r.status)
            except urllib.error.HTTPError as e:
                code = str(e.code)
            except Exception as e:  # noqa: BLE001
                reason = getattr(e, "reason", e)
                code = type(reason).__name__ if not isinstance(reason, str) else reason
            dt = time.monotonic() - t0
            with lock:
                lat.append(dt)
                codes[code] = codes.get(code, 0) + 1
            if per_worker:
                time.sleep(max(0.0, per_worker - dt))

    threads = [threading.Thread(target=worker, daemon=True) for _ in range(args.concurrency)]
    for t in threads:
        t.start()
    while any(t.is_alive() for t in threads):
        time.sleep(min(5, max(0.1, stop_at - time.monotonic())))
        if not args.quiet:
            with lock:
                print(f"load: {len(lat)} requests {codes}", file=sys.stderr, flush=True)
    lat.sort()

    def pct(p):
        return round(lat[min(len(lat) - 1, int(len(lat) * p))] * 1000, 1) if lat else None

    errors = sum(n for c, n in codes.items() if not (c.isdigit() and int(c) < 400))
    print(json.dumps({"url": args.url, "requests": len(lat), "errors": errors, "codes": codes,
                      "rps": round(len(lat) / args.duration, 1), "p50_ms": pct(0.50), "p90_ms": pct(0.90),
                      "p99_ms": pct(0.99), "max_ms": pct(1.0)}))
    return 1 if args.max_errors is not None and errors > args.max_errors else 0


def cmd_wait_for(args):
    host, _, port = args.target.rpartition(":") if args.target.count(":") == 1 else (args.target, "", "")
    deadline = time.monotonic() + args.timeout
    while True:
        try:
            socket.getaddrinfo(host, None)
            if port:
                socket.create_connection((host, int(port)), timeout=2).close()
            print(f"{args.target} is available", flush=True)
            return 0
        except (OSError, ValueError) as e:
            if time.monotonic() > deadline:
                print(f"timed out waiting for {args.target}: {e}", file=sys.stderr, flush=True)
                return 1
            print(f"waiting for {args.target}: {e}", flush=True)
            time.sleep(args.interval)


def cmd_ship_logs(args):
    f, inode = None, None
    while True:
        if f is None:
            try:
                f = open(args.file, errors="replace")
                inode = os.fstat(f.fileno()).st_ino
            except FileNotFoundError:
                time.sleep(1)
                continue
        line = f.readline()
        if line:
            sys.stdout.write(line)
            sys.stdout.flush()
            continue
        try:
            st = os.stat(args.file)
            if st.st_ino != inode or st.st_size < f.tell():
                f.close()
                f = None
                continue
        except FileNotFoundError:
            f.close()
            f = None
        time.sleep(0.5)


def main(argv):
    p = argparse.ArgumentParser(prog="labapp", description="kubernetes-lab demo service")
    sub = p.add_subparsers(dest="cmd")
    s = sub.add_parser("serve", help="run the HTTP service (default)")
    s.add_argument("--bind", help="listen address (overrides BIND_ADDRESS)")
    s.add_argument("--port", type=int, help="listen port (overrides PORT)")
    sub.add_parser("migrate", help="create and seed the items schema, then exit")
    g = sub.add_parser("get", help="HTTP request; body to stdout, exit 0 on 2xx/3xx")
    g.add_argument("url")
    g.add_argument("-X", "--method")
    g.add_argument("-H", "--header", action="append", default=[])
    g.add_argument("-d", "--data")
    g.add_argument("-k", "--insecure", action="store_true")
    g.add_argument("--cacert")
    g.add_argument("--expect", type=int, help="exit 0 only for this status code")
    g.add_argument("-q", "--quiet", action="store_true")
    g.add_argument("-v", "--verbose", action="store_true")
    g.add_argument("--timeout", type=float, default=5)
    ld = sub.add_parser("load", help="generate HTTP load, print a JSON summary")
    ld.add_argument("url")
    ld.add_argument("-c", "--concurrency", type=int, default=10)
    ld.add_argument("-d", "--duration", type=float, default=30)
    ld.add_argument("--rps", type=float, default=0, help="total requests/second (0 = as fast as possible)")
    ld.add_argument("--timeout", type=float, default=5)
    ld.add_argument("--max-errors", type=int, help="exit 1 when more errors than this")
    ld.add_argument("-q", "--quiet", action="store_true")
    w = sub.add_parser("wait-for", help="wait until HOST resolves (and HOST:PORT accepts TCP)")
    w.add_argument("target")
    w.add_argument("--timeout", type=float, default=300)
    w.add_argument("--interval", type=float, default=2)
    sl = sub.add_parser("ship-logs", help="follow a log file to stdout (handles rotation)")
    sl.add_argument("file")
    rs = sub.add_parser("read-secret", help="read a Secret via the Kubernetes API, print its key names")
    rs.add_argument("secret", help="[namespace/]name")
    sub.add_parser("version")

    if not argv or argv[0].startswith("-") and argv[0] not in ("-h", "--help"):
        argv = ["serve"] + argv
    args = p.parse_args(argv)
    if args.cmd == "serve":
        return cmd_serve(args)
    signal.signal(signal.SIGTERM, plain_exit)  # PID 1 ignores SIGTERM unless handled
    if args.cmd == "version":
        print(f"labapp {VERSION}")
        return 0
    return {"migrate": cmd_migrate, "get": cmd_get, "load": cmd_load, "wait-for": cmd_wait_for,
            "ship-logs": cmd_ship_logs, "read-secret": cmd_read_secret}[args.cmd](args)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(130)
