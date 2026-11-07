check_eventually 30 "billing /health is 200 via every node" all_nodes_http /health ok 3
verdict
