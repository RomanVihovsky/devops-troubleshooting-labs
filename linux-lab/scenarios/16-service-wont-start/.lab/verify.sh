runs_as_inventory() { local p; p=$(mainpid inventory-api); [ "$(sx "ps -o user= -p $p")" = inventory ]; }
check_eventually 10 "inventory-api is active" active inventory-api
check_eventually 10 "curl localhost:8083/ answers" sx 'curl -fs localhost:8083/'
check "runs as user inventory" runs_as_inventory
verdict
