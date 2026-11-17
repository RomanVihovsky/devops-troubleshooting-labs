private() { [ "$(kx -n web-prod get deploy web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d/ -f1)" = registry.lab:5001 ]; }
greets() { curl -s --max-time 5 -H 'Host: web.prod.lab' http://192.168.56.200/ | grep -q '^Howdy'; }
ok200() { [ "$(http_out http://192.168.56.200/ web.prod.lab)" = 200 ]; }
staging_kept() { [ "$(kx -n web-staging get secret regcred configmap web-config -o jsonpath='{.items[*].metadata.resourceVersion}' 2>/dev/null)" = "$(recall b05_staging)" ]; }
check_eventually 180 "web: 2 Ready pods in web-prod" deploy_ready web-prod web 2
check "pulled from registry.lab:5001" private
check_eventually 60 "http://web.prod.lab/ answers 200 through the ingress" ok200
check_eventually 30 "...with the greeting from its config" greets
check "staging is untouched" staging_kept
verdict
