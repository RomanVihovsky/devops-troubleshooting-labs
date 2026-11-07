check "/usr/bin/chmod is mode 755" sx '[ "$(stat -c %a /usr/bin/chmod)" = 755 ]'
check "it is the original binary" sx "[ \"\$(md5sum /usr/bin/chmod | cut -d' ' -f1)\" = '$(recall sum)' ]"
check "chmod works" sx '/usr/bin/chmod --version >/dev/null'
check "deploy.sh is executable and runs" as_user admin '/usr/local/bin/deploy.sh | grep -q deployed'
verdict
