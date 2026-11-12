port_8080() { [ "$(kx -n weather get deploy weather -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}')" = 8080 ]; }
check_eventually 60 "http://weather.weather/ -> 200 inside the cluster" http_ok weather http://weather.weather/
check "the app still listens on 8080" port_8080
verdict
