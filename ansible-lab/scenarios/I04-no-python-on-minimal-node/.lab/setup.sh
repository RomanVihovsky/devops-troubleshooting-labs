# the minimal image: no Python (libraries stay, interpreters and python3-apt go)
nx app1 "dpkg --purge --force-depends python3 python3-minimal python3.11 python3.11-minimal python3-apt >/dev/null 2>&1; test ! -e /usr/bin/python3"
run_logged "$SETUP_LOG" ctl "ansible-playbook site.yml" || true
