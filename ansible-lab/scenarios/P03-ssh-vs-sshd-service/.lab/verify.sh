banner_on() { nx "$1" "sshd -T" | grep -ix 'banner /etc/issue.net' >/dev/null; }
change_applies() {   # remove the drop-in on both nodes: one run must restore it and make sshd use it
  nx web1 "rm -f /etc/ssh/sshd_config.d/20-banner.conf && systemctl reload ssh" &&
  nx web2 "rm -f /etc/ssh/sshd_config.d/20-banner.conf && systemctl reload sshd" &&
  applies site.yml && banner_on web1 && banner_on web2
}
check "web1: sshd uses the banner" banner_on web1
check "web2: sshd uses the banner" banner_on web2
check "a banner config change is applied on both OS families in one run" change_applies
check "site.yml converges" converged site.yml
verdict
