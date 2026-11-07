check_eventually 40 "app_reports is 2/2" svc_converged app_reports
check_eventually 30 "reports answers via every node" all_nodes_http / 'reports v1.0'
verdict
