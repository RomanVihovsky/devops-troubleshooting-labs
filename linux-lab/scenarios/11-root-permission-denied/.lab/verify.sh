works_after_remount() {
  sx 'rm -f /var/lib/rotate/last-run; systemctl restart opt-tools.mount && systemctl start rotate-keys.service && test -s /var/lib/rotate/last-run'
}
check "rotate-keys works, also after re-mounting /opt/tools" works_after_remount
verdict
