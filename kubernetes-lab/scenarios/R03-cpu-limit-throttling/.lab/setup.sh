# R03: CPU-heavy requests (PBKDF2) under a 50m CPU limit - CFS throttling turns ms into seconds
kns quotes
ka -f quotes.yaml
wait_rollout quotes deploy/quotes 180
slow() { [ "$(load_test quotes http://quotes.quotes.svc:8080/items -c 4 -d 15 --rps 20 | jq '.p99_ms // 0 | floor')" -gt 500 ]; }
retry 60 slow || die "quotes is not slow"
