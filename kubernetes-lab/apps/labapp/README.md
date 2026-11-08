# labapp

The demo service behind most kubernetes-lab scenarios: one Python file, stdlib only,
on `python:3.12-slim`. Every behaviour a scenario needs is switched by an environment
variable that looks like an ordinary setting, so a broken manifest reads like a real one.

```bash
docker build -t labapp:dev apps/labapp      # unprivileged, no network needed beyond the base image
apps/labapp/smoke.sh labapp:dev             # ~50 docker-only checks (redis/postgres containers included)
apps/labapp/build.sh registry.lab:5000/lab  # every tag below; PUSH=1 to push
```

Listens on **8080**. Runs as **uid 10001** (gid 0). Python is PID 1 and handles signals itself.

## Image tags

| Tag | Build args | Used for |
|---|---|---|
| `1.4` | default | chart `appVersion`, every healthy baseline (P01: `1.4.0` does **not** exist) |
| `1.3` | `APP_VERSION=1.3` | the previous release: rollback target, history (W01, W11) |
| `1.5` | `APP_VERSION=1.5 REQUIRED_ENV=SESSION_SECRET` | broken release: exits 1 "required setting SESSION_SECRET is not set" (W01, W11) |
| `1.4-root` | `APP_UID=0` | image runs as root: `runAsNonRoot` rejects it (A05) |
| `2.0.0-rc1` | `APP_VERSION=2.0.0-rc1 REQUIRED_ENV=FEATURE_FLAGS_URL` | release candidate that exits 1 on start (D03) |

P03 (`exec format error`) needs an arm64 image under an amd64 tag. `build.sh` doesn't make one (no
emulation on this host); copy any arm64 image there, e.g. `crane copy --platform linux/arm64
python:3.12-slim registry.lab:5000/lab/labapp:1.6`.

## Settings

Secrets marked **F** can also come from a file: `NAME_FILE=/path`. The file is re-read on every use,
so a rotated, mounted Secret is picked up without a restart; an env var keeps its start-up value (Y07).
Secret values are **never stripped**: a trailing newline from `kubectl create secret --from-file` is
sent as-is (C07). `/env` and `/config` show secrets as `<set>` only, and URLs as `user:***@`.

### Service

| Variable | Default | Effect | Rows |
|---|---|---|---|
| `PORT` | `8080` | listen port (`serve --port` overrides) | P09 N02 N03 X04 |
| `BIND_ADDRESS` | `0.0.0.0` | listen address; `127.0.0.1` works via port-forward but not via a Service. `serve --bind` overrides | N14 |
| `APP_NAME` | `labapp` | name in `/`, `/items`, `/version` and logs | W03 |
| `GREETING` | `Hello` | first word of `/` (read at start-up) | C01 |
| `CONFIG_FILE` | - | `key = value` (or JSON) file, re-read per request; `greeting` overrides `GREETING`; shown in `/config` | C02 |
| `BASE_PATH` | - | serve the app under a prefix (`/api/items`); without it `/api/items` is 404 | G03 |
| `ALLOWED_HOSTS` | `*` | comma list of virtual hosts (`.example.com` = domain + subdomains); others get 404. Probes are exempt | N13 G07 |
| `TLS_CERT_FILE` / `TLS_KEY_FILE` | - | serve HTTPS instead of HTTP | |
| `REQUIRED_ENV` | - | comma list of settings that must be non-empty (or have `_FILE`), else exit 1 | P04 W01 |
| `MAINTENANCE_FILE` | - | `/ready` is 503 while this file exists | W04 |

### Start-up, resources, load

| Variable | Default | Effect | Rows |
|---|---|---|---|
| `WARMUP_SECONDS` | `0` | "loading dataset": the port opens only after this many seconds | P11 |
| `CACHE_MB` | `0` | in-memory cache size (really resident) | P08 Q02 R04 |
| `CACHE_WARMUP` | `eager` | `eager` = fill at start-up; `lazy` = +4 MiB per `/` or `/items` request until full ("restarts under load") | P08 |
| `DISK_CACHE_MB` | `0` | write this many MiB of cache files into `CACHE_DIR` after start-up | P15 |
| `CACHE_DIR` | `$WORK_DIR/cache` | where the disk cache goes (point it at an emptyDir) | P15 |
| `WORK_DIR` | `/tmp/labapp` | always created and written at start-up: a read-only rootfs without a `/tmp` volume exits 1 | A06 |
| `DATA_DIR` | - | persistent data (`/kv`); must be writable at start-up (exit 1 "permission denied"); readiness checks it | V03 V05 V06 V10 |
| `WORKER_THREADS` | `16` | request threads, all started up front: a low pids limit exits 1 "can't start new thread" | R07 |
| `INDEXER_WORKERS` | `0` | background "search indexer" threads that burn CPU forever | Q03 |
| `HASH_ITERATIONS` | `0` | PBKDF2 rounds per `/` and `/items` request (session hashing): per-request CPU cost | R01 R03 R09 |
| `MAX_UPLOAD_MB` | `64` | `/upload` limit (413 above it) | G08 |
| `ERROR_RATE` | `0` | fraction of `GET /items` answered 500 ("pricing service timeout"), logged | Q05 |

### Logging and shutdown

| Variable | Default | Effect | Rows |
|---|---|---|---|
| `LOG_LEVEL` | `info` | `debug` also logs probe requests | |
| `LOG_FORMAT` | `text` | `text` or `json` | |
| `LOG_FILE` | - | log only to this file (stdout stays empty; `FATAL` also goes to stderr). The image has `/var/log/labapp/` writable for uid 10001 | Q01 |
| `ACCESS_LOG` | `true` | one line per request: `GET /items 200 ms=1.2 client=…` | Q05 |
| `SHUTDOWN_MODE` | `graceful` | on SIGTERM: `graceful` = `/ready` 503, close the listener, finish in-flight requests, exit 0; `immediate` = exit 0 at once (in-flight dropped); `ignore` = log and keep running until SIGKILL | P13 P16 |
| `SHUTDOWN_DELAY_SECONDS` | `0` | graceful: keep accepting this long after SIGTERM (an in-app preStop sleep) | P16 |
| `SHUTDOWN_TIMEOUT_SECONDS` | `25` | graceful: give up draining after this | P16 |

### Dependencies

| Variable | Default | Effect | Rows |
|---|---|---|---|
| `STORAGE_BACKEND` | `memory` | where `/items` lives: `memory`, `redis` (needs `REDIS_HOST`) or `postgres` (needs `DATABASE_URL`, else exit 1) | P04 |
| `AUTO_MIGRATE` | `false` | run `migrate` in the background at start-up; `/ready` is 503 until it succeeds | D09 |
| `READY_CHECK_DEPENDENCIES` | `true` | `/ready` checks redis, postgres, the upstream (if required) and `DATA_DIR` | |
| `HEALTH_CHECK_DEPENDENCIES` | `false` | `/health` checks them too (liveness anti-pattern: restarts on a DB outage) | |
| `REDIS_HOST` | - | enables redis: `/` hit counter, readiness check, `redis` backend | C03 |
| `REDIS_PORT` | `6379` | read only when `REDIS_HOST` is set. Strictly an integer, so a service link `REDIS_PORT=tcp://10.96.x.y:6379` (Service named `redis`, no explicit value) exits 1 | |
| `REDIS_DB` / `REDIS_USERNAME` | `0` / - | database index; ACL user for `AUTH` | |
| `REDIS_PASSWORD` **F** | - | sent with `AUTH`; failure logs "authentication failed (invalid password?): WRONGPASS …" | C03 |
| `DATABASE_URL` **F** | - | `postgres://user:pass@host:5432/db`; cleartext, md5 and SCRAM-SHA-256 auth | P04 N10 B04 |
| `DATABASE_PASSWORD` **F** | - | overrides the password in `DATABASE_URL` | B04 |
| `UPSTREAM_URL` | - | called on every `/` (and by `/upstream`); a DNS lookup per call | N08 |
| `UPSTREAM_TOKEN` **F** | - | sent as `Authorization: Bearer <token>`; a trailing newline fails with "Invalid return character or leading space in header: Authorization" | C07 |
| `UPSTREAM_HOST` | - | override the `Host` header (SNI stays the URL host) | N13 |
| `UPSTREAM_REQUIRED` | `false` | include the upstream in `/ready` | |
| `UPSTREAM_TIMEOUT_SECONDS` / `UPSTREAM_CA_FILE` | `3` / system CAs | timeout; CA bundle for an https upstream | |
| `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` | - | honoured for upstream calls (an injected proxy breaks them) | A10 |
| `AUTH_TOKEN` **F** | - | require `Authorization: Bearer <token>` (exact, byte-for-byte) on every non-ops endpoint; 401 otherwise | C07 |

### Peers and identity

| Variable | Default | Effect | Rows |
|---|---|---|---|
| `PEER_DISCOVERY` | `none` | `dns` = resolve `PEER_SERVICE` (a headless Service gives every pod IP, a ClusterIP gives one); `kubernetes` = list pods via the API with the pod's ServiceAccount token. Refreshed every `PEER_REFRESH_SECONDS` (30); errors are logged, e.g. `pods is forbidden: User "system:serviceaccount:…" cannot list…` | N09 A01 A03 |
| `PEER_SERVICE` | - | DNS name for `dns` mode | N09 |
| `CREDENTIALS_SECRET` | - | `[namespace/]name`: read that Secret **through the Kubernetes API** with the pod's ServiceAccount (needs RBAC `get secrets`; `secretKeyRef`/volumes don't). Its keys back any secret setting not set otherwise (`auth-token` → `AUTH_TOKEN`); `/ready` reports `credentials`; a 403 is logged with the API's message. Cached 30 s | A12 |
| `PEER_SELECTOR` | `app.kubernetes.io/name=$APP_NAME` | label selector for `kubernetes` mode. Without a mounted token the API client fails like client-go: "unable to load in-cluster configuration: open …/token: no such file or directory" | A03 |
| `POD_NAME` `POD_IP` `POD_NAMESPACE` `NODE_NAME` | - | downward API values shown in `/version` and `/env` | C08 |

`labapp migrate` also reads `MIGRATE_TIMEOUT_SECONDS` (60: retry the DB this long) and `MIGRATE_SECONDS`
(0: extra sleep before "done").

## Endpoints

Ops endpoints (`/health`, `/ready`, `/metrics`) answer at `/` whatever `BASE_PATH`/`ALLOWED_HOSTS` say.
`/version`, `/env`, `/config` and `/peers` never need `AUTH_TOKEN`.

| Path | What |
|---|---|
| `GET /` | `Hello from <pod> (labapp v1.4)` + ` hits=N` (redis) + ` upstream=200 (3ms)` (upstream); 502 if a dependency fails |
| `GET /health` | liveness: `ok` (deps only with `HEALTH_CHECK_DEPENDENCIES`). There is no `/healthz` |
| `GET /ready` | readiness JSON: shutdown, maintenance, schema, redis, postgres, upstream, data_dir → 200/503 |
| `GET /metrics` | Prometheus text: requests by code, in-flight, uptime, cache bytes |
| `GET /version` | name, version, hostname, pod IP, node, uptime |
| `GET /env` | environment, secrets masked, service-link vars hidden (`?all=1` shows them) |
| `GET /config` | effective settings, secret presence, redacted `DATABASE_URL`, parsed `CONFIG_FILE` |
| `GET /peers` | discovered peers (`?probe=1` asks each for its hostname) |
| `GET/POST /items` | catalogue from the storage backend (`POST {"name":…, "price":…}`); `served_by` names the pod |
| `GET /upstream` | call `UPSTREAM_URL`, report status/body |
| `GET /burn?ms=200` | burn CPU for that long (multi-core: PBKDF2 releases the GIL) |
| `GET /alloc?mb=64` | retain more memory (`?free=1` releases) |
| `GET /big?kb=N` / `?mb=N` | large response (streamed) |
| `GET /slow?ms=N` | slow response (in-flight requests for shutdown tests) |
| `GET /status/<code>` | answer with that status |
| `POST/PUT /upload` | read the body, return size + sha256 (chunked OK) |
| `GET/PUT/DELETE /kv/<key>` | small values in `DATA_DIR/kv/` (`GET /kv/` lists) |
| `GET/POST /admin/crash?code=N&msg=…` | log `FATAL: <msg>` and exit with that code (forensics setups) |

## Subcommands

The image's entrypoint is `labapp`, the default command `serve`, so `args: ["--bind", "127.0.0.1"]` works
and `command: ["gunicorn"]` fails as it should (P07: there is no gunicorn). python:3.12-slim has no curl
or nslookup; use these instead:

| Command | Use |
|---|---|
| `labapp [serve] [--bind A] [--port N]` | the service |
| `labapp migrate` | create + seed `items` (postgres), seed the redis list, or nothing (memory); prints `… done`, exits 0 (P05, migration Jobs/hooks) |
| `labapp get URL [-X M] [-H 'K: V'] [-d D] [--expect N] [-q]` | curl stand-in for exec probes and verify scripts; exit 0 on 2xx/3xx (or `--expect`) |
| `labapp load URL [-c 10] [-d 30] [--rps N] [--max-errors N]` | load generator; JSON summary with codes and p50/p90/p99 (P16 R01 R03 R09) |
| `labapp wait-for HOST[:PORT] [--timeout 300]` | init container: wait for DNS (and TCP) (P12) |
| `labapp ship-logs FILE` | sidecar: follow a file to stdout, survives rotation (P14 Q01) |
| `labapp read-secret [NS/]NAME` | read a Secret via the API with the pod's ServiceAccount, print key names only; exit 1 with the API error (A12 as a Job) |
| `labapp version` | print the version |
