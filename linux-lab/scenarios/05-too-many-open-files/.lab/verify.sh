nofile_ok() {
  local pid
  pid=$(mainpid catalog-api); [ -n "$pid" ] && [ "$pid" != 0 ] || return 1
  sx "awk '/Max open files/{exit !(\$4 >= 4096)}' /proc/$pid/limits"
}
check_eventually 15 "catalog-api is running" active catalog-api
check_eventually 15 "curl localhost:8081/ -> 200" sx 'curl -fs localhost:8081/'
check "catalog-api may open >= 4096 files" nofile_ok
verdict
