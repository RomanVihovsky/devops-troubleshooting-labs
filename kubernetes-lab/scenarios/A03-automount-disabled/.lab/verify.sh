# the API server pretty-prints JSON for curl/wget user agents: "kind": "PodList"
api_ok() {
  kx -n janitor exec deploy/janitor -- sh -c 'T=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) && wget -q -O - --no-check-certificate --header "Authorization: Bearer $T" https://kubernetes.default.svc/api/v1/namespaces/janitor/pods | grep -q "\"kind\": *\"PodList\""' >/dev/null 2>&1
}
default_off() { [ "$(kx -n janitor get sa default -o jsonpath='{.automountServiceAccountToken}')" = false ]; }
check_eventually 90 "janitor lists pods through the API with its token" api_ok
check "the default ServiceAccount keeps automount off" default_off
verdict
