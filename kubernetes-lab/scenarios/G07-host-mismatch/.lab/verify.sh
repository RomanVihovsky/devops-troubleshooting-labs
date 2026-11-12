from_store() { curl -s --max-time 5 -H "Host: $1" http://192.168.56.200/version | grep -q '"name": *"store"'; }
check_eventually 60 "store.lab answers from the store app" from_store store.lab
check_eventually 60 "www.store.lab answers from the store app" from_store www.store.lab
verdict
