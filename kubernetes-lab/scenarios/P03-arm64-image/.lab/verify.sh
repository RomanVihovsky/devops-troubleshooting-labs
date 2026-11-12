img() { kx -n analytics get deploy etl -o jsonpath='{.spec.template.spec.containers[0].image}'; }
amd64() { local i; i=$(img); case $i in registry.lab:5000/lab/labapp:*) ;; *) return 1 ;; esac
          [ "$(nx k8s-gw "crane config --insecure $i 2>/dev/null | jq -r '.os + \"/\" + .architecture'" </dev/null)" = linux/amd64 ]; }
check_eventually 150 "etl: 2 Ready pods" deploy_ready analytics etl 2
check_eventually 90 "etl stable for 30 s" stable_for 30 analytics app=etl
check "etl runs a registry.lab:5000/lab/labapp image built for linux/amd64" amd64
verdict
