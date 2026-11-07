audit_intact() {
  sx "lsattr /var/log/app/audit.log | cut -c1-22 | grep -q a" &&
  [ "$(sx 'head -5 /var/log/app/audit.log | md5sum')" = "$(recall audit)" ]
}
check "app.conf says mode = production" sx "grep -Eq '^mode *= *production' /etc/app/app.conf"
check "app.conf is changeable again (not immutable)" sx "! lsattr /etc/app/app.conf | cut -c1-22 | grep -q i"
check "audit.log kept its content and append-only protection" audit_intact
verdict
