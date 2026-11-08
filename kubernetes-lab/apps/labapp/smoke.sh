#!/usr/bin/env bash
# Smoke-test a labapp image with plain docker (no cluster, no privileges).
#   apps/labapp/smoke.sh [image]        default image: labapp:dev
# Starts throwaway redis/postgres containers on a private network; cleans up on exit.
set -uo pipefail
IMG=${1:-labapp:dev}
NET=labapp-smoke
P=labapp-smoke
REDIS_IMG=${REDIS_IMG:-redis:7-alpine}
PG_IMG=${PG_IMG:-postgres:16-alpine}
pass=0 fail=0

cleanup() {
  docker ps -aq --filter "name=^${P}-" | xargs -r docker rm -f >/dev/null 2>&1
  docker network rm "$NET" >/dev/null 2>&1
}
trap cleanup EXIT
ok()  { echo "  ok   $*"; pass=$((pass + 1)); }
bad() { echo "  FAIL $*"; fail=$((fail + 1)); }
check() { # description command...
  local d=$1; shift
  if out=$("$@" 2>&1); then ok "$d"; else bad "$d"; echo "$out" | sed 's/^/       /' | tail -5; fi
}
run() { # name [docker run args...] -- [labapp args...]
  local name=$1; shift
  docker run -d --name "$P-$name" --network "$NET" --network-alias "$name" "$@" >/dev/null
}
get() { docker exec "$P-$1" labapp get -q "${@:2}"; }       # exit status of a request from inside
body() { docker exec "$P-$1" labapp get "${@:2}" 2>/dev/null; }
wait_up() { # name
  for _ in $(seq 1 40); do docker exec "$P-$1" labapp get -q http://127.0.0.1:8080/health 2>/dev/null && return 0; sleep 0.25; done
  return 1
}
exited() { # name -> exit code once stopped
  for _ in $(seq 1 40); do
    [[ $(docker inspect -f '{{.State.Running}}' "$P-$1") == false ]] && { docker inspect -f '{{.State.ExitCode}}' "$P-$1"; return; }
    sleep 0.25
  done
  echo running
}

cleanup
docker network create "$NET" >/dev/null

echo "== basics"
run web "$IMG"
wait_up web
check "/health 200"            get web http://127.0.0.1:8080/health
check "/ready 200"             get web http://127.0.0.1:8080/ready
check "/healthz is 404"        get web --expect 404 http://127.0.0.1:8080/healthz
check "/items 200"             get web http://127.0.0.1:8080/items
check "/version reports 1.4"   bash -c "docker exec $P-web labapp get http://127.0.0.1:8080/version | grep -q '\"version\": \"1.4\"'"
check "/big?mb=5 is 5 MiB"     bash -c "[ \$(docker exec $P-web labapp get http://127.0.0.1:8080/big?mb=5 | wc -c) = 5242880 ]"
check "upload 10 MiB"          bash -c "head -c 10485760 /dev/zero | docker exec -i $P-web python -c 'import sys,urllib.request as u; print(u.urlopen(u.Request(\"http://127.0.0.1:8080/upload\", data=sys.stdin.buffer.read(), method=\"POST\")).status)' | grep -q 200"
check "/burn uses CPU"         bash -c "docker exec $P-web labapp get 'http://127.0.0.1:8080/burn?ms=300' | grep -q burned_ms"
check "runs as uid 10001"      bash -c "[ \$(docker exec $P-web python -c 'import os; print(os.getuid())') = 10001 ]"

echo "== env / config never show secret values"
run cfg -e REDIS_HOST=nowhere -e REDIS_PASSWORD=hunter2 -e AUTH_TOKEN=t0p -e DATABASE_URL=postgres://app:pgpw@db/app "$IMG"
wait_up cfg
check "/env masks secrets"     bash -c "out=\$(docker exec $P-cfg labapp get http://127.0.0.1:8080/env); ! grep -qE 'hunter2|t0p|pgpw' <<<\"\$out\" && grep -q '\"REDIS_PASSWORD\": \"<set>\"' <<<\"\$out\""
check "/config masks secrets"  bash -c "out=\$(docker exec $P-cfg labapp get http://127.0.0.1:8080/config); ! grep -qE 'hunter2|t0p|pgpw' <<<\"\$out\" && grep -q 'postgres://app:\*\*\*@db/app' <<<\"\$out\""

echo "== crash on missing required settings"
check "REQUIRED_ENV exits 1"   bash -c "docker run --rm -e REQUIRED_ENV=DATABASE_URL $IMG 2>&1 | grep -q 'required setting DATABASE_URL is not set'; [ \${PIPESTATUS[0]} = 1 ]"
check "postgres w/o DATABASE_URL exits 1" bash -c "docker run --rm -e STORAGE_BACKEND=postgres -e DB_URL=postgres://x $IMG >/dev/null 2>&1; [ \$? = 1 ]"

echo "== redis with AUTH"
run redis "$REDIS_IMG" redis-server --requirepass s3cret
run rgood -e REDIS_HOST=redis -e REDIS_PASSWORD=s3cret "$IMG"
run rbad  -e REDIS_HOST=redis -e REDIS_PASSWORD="$(printf s3cret | base64)" "$IMG"
wait_up rgood; wait_up rbad; sleep 0.5
check "good password: ready"   get rgood http://127.0.0.1:8080/ready
check "good password: hits"    bash -c "docker exec $P-rgood labapp get http://127.0.0.1:8080/ | grep -q 'hits=1'"
check "bad password: 503"      get rbad --expect 503 http://127.0.0.1:8080/ready
check "bad password: logs say invalid password" bash -c "docker exec $P-rbad labapp get -q http://127.0.0.1:8080/ready; docker logs $P-rbad 2>&1 | grep -q 'invalid password'"

echo "== postgres (SCRAM) + migrate"
run db -e POSTGRES_USER=shop -e POSTGRES_PASSWORD=pgpw -e POSTGRES_DB=shop "$PG_IMG"
docker run --rm --network "$NET" "$IMG" wait-for db:5432 --timeout 60 >/dev/null
sleep 3  # initdb restarts the server once
check "migrate exits 0 + done" bash -c "docker run --rm --network $NET -e STORAGE_BACKEND=postgres -e DATABASE_URL=postgres://shop:pgpw@db/shop $IMG migrate | grep -q done"
run api -e STORAGE_BACKEND=postgres -e DATABASE_URL=postgres://shop:pgpw@db/shop -e AUTH_TOKEN=tok123 "$IMG"
run apibad -e STORAGE_BACKEND=postgres -e DATABASE_URL=postgres://shop:wrong@db/shop "$IMG"
wait_up api; wait_up apibad
check "api ready (postgres ok)" get api http://127.0.0.1:8080/ready
check "wrong db password: 503" bash -c "docker exec $P-apibad labapp get http://127.0.0.1:8080/ready | grep -q 'password authentication failed'"
check "items need a token (401)" get api --expect 401 http://127.0.0.1:8080/items
check "items from postgres"    bash -c "docker exec $P-api labapp get -H 'Authorization: Bearer tok123' http://127.0.0.1:8080/items | grep -q '\"source\": \"postgres\"'"
check "POST item persists"     bash -c "docker exec $P-api labapp get -H 'Authorization: Bearer tok123' -d '{\"name\":\"tea\",\"price\":1.5}' http://127.0.0.1:8080/items >/dev/null && docker exec $P-api labapp get -H 'Authorization: Bearer tok123' http://127.0.0.1:8080/items | grep -q tea"

echo "== bearer token to an upstream"
run front -e UPSTREAM_URL=http://api:8080/items -e UPSTREAM_TOKEN=tok123 -e UPSTREAM_REQUIRED=true "$IMG"
run frontnl -e UPSTREAM_URL=http://api:8080/items -e UPSTREAM_TOKEN=$'tok123\n' "$IMG"   # kubectl create secret --from-file
run frontbad -e UPSTREAM_URL=http://api:8080/items -e UPSTREAM_TOKEN=wrong "$IMG"
wait_up front; wait_up frontnl; wait_up frontbad
check "frontend -> api 200"    bash -c "docker exec $P-front labapp get http://127.0.0.1:8080/ | grep -q 'upstream=200'"
check "frontend ready incl. upstream" get front http://127.0.0.1:8080/ready
check "token with newline: 502" bash -c "docker exec $P-frontnl labapp get http://127.0.0.1:8080/upstream | grep -q 'Invalid return character'"
check "wrong token: upstream 401" bash -c "docker exec $P-frontbad labapp get http://127.0.0.1:8080/upstream | grep -q '\"status\": 401'"

echo "== networking switches"
run lo -e BIND_ADDRESS=127.0.0.1 "$IMG"
run loarg "$IMG" serve --bind 127.0.0.1
wait_up lo; wait_up loarg
check "BIND_ADDRESS=127.0.0.1 unreachable from peers" bash -c "! docker exec $P-web labapp get -q --timeout 2 http://lo:8080/health 2>/dev/null"
check "--bind 127.0.0.1 unreachable from peers" bash -c "! docker exec $P-web labapp get -q --timeout 2 http://loarg:8080/health 2>/dev/null"
run bp -e BASE_PATH=/api -e ALLOWED_HOSTS=shop.lab,.example.com "$IMG"
wait_up bp
check "BASE_PATH: /api/items 200" get bp -H 'Host: shop.lab' http://127.0.0.1:8080/api/items
check "BASE_PATH: /items 404" get bp --expect 404 -H 'Host: shop.lab' http://127.0.0.1:8080/items
check "ALLOWED_HOSTS: other host 404" get bp --expect 404 -H 'Host: www.shop.lab' http://127.0.0.1:8080/api/items
check "ALLOWED_HOSTS: probes exempt" get bp http://127.0.0.1:8080/ready
for i in 1 2 3; do docker run -d --name "$P-peer$i" --network "$NET" --network-alias peers "$IMG" >/dev/null; done
run disc -e PEER_DISCOVERY=dns -e PEER_SERVICE=peers "$IMG"
wait_up disc
check "/peers lists 3 (dns)"   bash -c "docker exec $P-disc labapp get http://127.0.0.1:8080/peers | grep -q '\"count\": 3'"

echo "== start-up and shutdown"
run warm -e WARMUP_SECONDS=4 "$IMG"
sleep 1
check "warm-up: not listening yet" bash -c "! docker exec $P-warm labapp get -q --timeout 1 http://127.0.0.1:8080/health 2>/dev/null"
sleep 4.5
check "warm-up: listening after" get warm http://127.0.0.1:8080/health
run graceful -e SHUTDOWN_DELAY_SECONDS=1 "$IMG"; wait_up graceful
docker exec "$P-graceful" labapp get -q 'http://127.0.0.1:8080/slow?ms=2500' >/dev/null 2>&1 & inflight=$!
sleep 0.3; docker kill -s TERM "$P-graceful" >/dev/null; sleep 0.3
check "graceful: /ready 503 while draining" get graceful --expect 503 http://127.0.0.1:8080/ready
if wait $inflight; then ok "graceful: in-flight request completes"; else bad "graceful: in-flight request completes"; fi
code=$(exited graceful); [[ $code == 0 ]] && ok "graceful: exit 0" || bad "graceful: exit 0 (got $code)"
run immediate -e SHUTDOWN_MODE=immediate "$IMG"; wait_up immediate
docker exec "$P-immediate" labapp get -q 'http://127.0.0.1:8080/slow?ms=2500' >/dev/null 2>&1 & inflight=$!
sleep 0.3; docker kill -s TERM "$P-immediate" >/dev/null
if wait $inflight; then bad "immediate: in-flight request dropped"; else ok "immediate: in-flight request dropped"; fi
run ignore -e SHUTDOWN_MODE=ignore "$IMG"; wait_up ignore
check "SHUTDOWN_MODE=ignore survives SIGTERM" bash -c "docker kill -s TERM $P-ignore >/dev/null; sleep 1; docker exec $P-ignore labapp get -q http://127.0.0.1:8080/health && docker logs $P-ignore 2>&1 | grep -q 'SIGTERM received - ignored'"

echo "== resources and filesystem"
run oom --memory 128m --memory-swap 128m -e CACHE_MB=192 "$IMG"
exited oom >/dev/null
check "CACHE_MB=192 under 128m: OOMKilled" bash -c "[ \$(docker inspect -f '{{.State.OOMKilled}}' $P-oom) = true ]"
check "WORKER_THREADS=100 under pids 64: exits 1" bash -c "docker run --rm --pids-limit 64 -e WORKER_THREADS=100 $IMG 2>&1 | grep -q \"can't start new thread\""
check "read-only rootfs: exits 1" bash -c "docker run --rm --read-only $IMG 2>&1 | grep -q 'Read-only file system'"
run rofs --read-only --tmpfs /tmp "$IMG"; wait_up rofs
check "read-only rootfs + /tmp tmpfs: ok" get rofs http://127.0.0.1:8080/ready
run kv -e DATA_DIR=/data "$IMG"; wait_up kv
check "kv put/get"             bash -c "docker exec $P-kv labapp get -X PUT -d hello http://127.0.0.1:8080/kv/greeting >/dev/null && [ \$(docker exec $P-kv labapp get http://127.0.0.1:8080/kv/greeting) = hello ]"
check "DATA_DIR not writable: exits 1" bash -c "docker run --rm -e DATA_DIR=/etc/labapp-data $IMG 2>&1 | grep -q 'cannot write to DATA_DIR'"
run filelog -e LOG_FILE=/var/log/labapp/app.log "$IMG"; wait_up filelog
get filelog http://127.0.0.1:8080/ >/dev/null
check "LOG_FILE: docker logs empty" bash -c "[ -z \"\$(docker logs $P-filelog 2>&1)\" ]"
check "ship-logs follows the file" bash -c "timeout 3 docker exec $P-filelog labapp ship-logs /var/log/labapp/app.log | grep -q 'GET / 200'"

echo "== tools"
check "labapp load"            bash -c "docker exec $P-web labapp load -q -c 4 -d 2 http://127.0.0.1:8080/ | grep -q '\"errors\": 0'"
check "labapp wait-for timeout" bash -c "! docker exec $P-web labapp wait-for nosuchhost:5432 --timeout 2 --interval 0.5 >/dev/null 2>&1"
check "labapp migrate (memory) done" bash -c "docker run --rm $IMG migrate | grep -q done"

echo
echo "smoke: $pass passed, $fail failed"
[[ $fail == 0 ]]
