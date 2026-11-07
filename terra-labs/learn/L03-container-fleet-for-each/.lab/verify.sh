label_ok() { [ "$(docker inspect -f '{{index .Config.Labels "service"}}|{{index .Config.Labels "terralab.scenario"}}' "tfl-fleet-$1" 2>/dev/null)" = "$1|L03" ]; }
mem_is()   { [ "$(docker inspect -f '{{.HostConfig.Memory}}' "tfl-fleet-$1" 2>/dev/null)" = "$(( $2 * 1024 * 1024 ))" ]; }
answers()  { curl -fs --max-time 3 "http://127.0.0.1:$1/" | grep -qi nginx; }
endpoints_ok() {
  ci_init fleet && [ "$(ci_tf fleet output -json endpoints 2>/dev/null | jq -c 'keys')" = '["static","web"]' ]
}
check "tfl-fleet-web and tfl-fleet-static are running" eval 'ctr_running tfl-fleet-web && ctr_running tfl-fleet-static'
check "tfl-fleet-api is gone" not docker inspect tfl-fleet-api
check "labels: service=<key>, terralab.scenario=L03" eval 'label_ok web && label_ok static'
check "memory limits: web 64 MiB, static 32 MiB" eval 'mem_is web 64 && mem_is static 32'
check_eventually 10 "web answers on 127.0.0.1:18081, static on :18083" eval 'answers 18081 && answers 18083'
check "output endpoints = {web, static}" endpoints_ok
check "state is keyed by service name (for_each)" state_has_re fleet '^docker_container\.[a-z_]+\["web"\]$'
check "CI plan of fleet/ shows no changes" plan_clean fleet
verdict
