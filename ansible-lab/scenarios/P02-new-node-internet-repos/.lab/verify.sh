reimage() { nx web2 "rm -f /etc/yum.repos.d/*.repo && cp /root/repos.orig/*.repo /etc/yum.repos.d/ && dnf clean all -q"; }
only_mirror() {
  local urls; urls=$(nx web2 "dnf -q repoinfo --enabled 2>/dev/null | grep -i '^Repo-baseurl'")
  echo "$urls" >> "$VERIFY_LOG"
  [ -n "$urls" ] && ! echo "$urls" | grep -v 'repo.acme.internal' | grep -q .
}
reimaged_converges() { reimage && applies site.yml; }
check "a freshly re-imaged node converges in one run" reimaged_converges
check "web2 serves the home page" eval '[ "$(http_get http://web2/)" = "ACME on web2" ]'
check "every enabled repo on web2 is the internal mirror" only_mirror
check "site.yml converges" converged site.yml
verdict
