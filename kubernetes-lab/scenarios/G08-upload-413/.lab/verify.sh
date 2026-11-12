up10() { [ "$(head -c 10485760 /dev/zero | curl -s -o /dev/null -w '%{http_code}' --max-time 60 -H 'Host: media.lab' --data-binary @- http://192.168.56.200/upload)" = 200 ]; }
# the middleware attached to the media Ingress still limits the body to 16-64 MiB
limit_ok() {
  local mw ns name
  mw=$(kx -n media get ingress media -o jsonpath='{.metadata.annotations.traefik\.ingress\.kubernetes\.io/router\.middlewares}')
  [ -n "$mw" ] || return 1
  for m in ${mw//,/ }; do
    m=${m%@kubernetescrd}; ns=${m%%-*}; name=${m#*-}
    kx -n "$ns" get middleware "$name" -o json 2>/dev/null | jq -e '.spec.buffering.maxRequestBodyBytes as $b | $b >= 16777216 and $b <= 67108864' >/dev/null && return 0
  done
  return 1
}
check_eventually 60 "a 10 MiB upload through media.lab answers 200" up10
check "the ingress still limits the body to 16-64 MiB" limit_ok
verdict
