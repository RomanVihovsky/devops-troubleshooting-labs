named_web() { [ "$(kx -n maps get deploy maps -o jsonpath='{.spec.template.spec.containers[0].ports[0].name}')" = web ]; }
check_eventually 60 "http://maps.maps/ -> 200 inside the cluster" http_ok maps http://maps.maps/
check "the container port is still named web" named_web
verdict
