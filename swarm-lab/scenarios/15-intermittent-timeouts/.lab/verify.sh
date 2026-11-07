check_eventually 20 "10 requests via every node answer with hits=" all_nodes_http / 'hits=' 10
verdict
