check_eventually 30 "app_web is 3/3" svc_converged app_web
check_eventually 30 "every node answers 'Welcome'" all_nodes_http / 'Welcome from'
verdict
