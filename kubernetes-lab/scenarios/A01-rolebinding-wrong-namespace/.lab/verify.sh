SA=system:serviceaccount:monitor:scraper
check "scraper can list pods in monitor" can_i "$SA" list pods -n monitor
check "scraper can NOT list pods in default" not can_i "$SA" list pods -n default
check "scraper can NOT list pods in kube-system" not can_i "$SA" list pods -n kube-system
check "scraper can NOT delete pods in monitor" not can_i "$SA" delete pods -n monitor
check "scraper can NOT read secrets in monitor" not can_i "$SA" get secrets -n monitor
verdict
