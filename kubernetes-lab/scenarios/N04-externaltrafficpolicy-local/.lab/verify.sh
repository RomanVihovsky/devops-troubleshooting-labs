all_nodes() { local w; for w in $(workers); do [ "$(http_out "http://$(node_ip "$w"):30480/")" = 200 ] || return 1; done; }
check_eventually 60 "NodePort 30480 answers 200 on every worker (from the desktop)" all_nodes
verdict
