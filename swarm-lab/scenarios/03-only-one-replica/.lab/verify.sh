check_eventually 60 "app_api is 3/3" svc_converged app_api
check "one replica on each of the 3 nodes" svc_on_all_nodes app_api 3
check_eventually 30 "report-api v1.4 answers via every node" all_nodes_http / 'report-api v1.4'
verdict
