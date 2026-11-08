hdr() { docker exec "$CTL" curl -fsS -D - -o /dev/null --max-time 5 "http://$1:8081/" 2>/dev/null | grep -qi '^X-Tier: frontend'; }
no_group_warning() {
  ctl_ci "ansible-playbook site.yml --check" > "$CI/.lab-run.log" 2>&1; local rc=$?
  cat "$CI/.lab-run.log" >> "$VERIFY_LOG"
  [ $rc -eq 0 ] && ! grep -qi 'invalid characters.*group' "$CI/.lab-run.log"
}
check "web1 and web2 serve on 8081 with X-Tier: frontend" eval 'hdr web1 && hdr web2'
check "no warning about invalid group names" no_group_warning
check "site.yml converges" converged site.yml
verdict
