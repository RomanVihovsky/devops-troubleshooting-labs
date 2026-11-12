app_answers() { curl -s --max-time 5 -H 'Host: gallery.lab' http://192.168.56.200/version | grep -q '"name": *"gallery"'; }
via_ingress() { [ "$(kx -n gallery get ingress -o name | wc -l)" -ge 1 ]; }
ok200() { [ "$(http_out http://192.168.56.200/ gallery.lab)" = 200 ]; }
check_eventually 60 "gallery.lab answers 200" ok200
check_eventually 30 "...from the gallery app" app_answers
check "served through an Ingress" via_ingress
verdict
