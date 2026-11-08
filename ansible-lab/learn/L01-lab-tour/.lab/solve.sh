cat > inventory/hosts.yml <<'YML'
all:
  children:
    web:
      hosts:
        web1:
        web2:
      vars:
        tier: frontend
YML
sed -i 's|^# TODO: default inventory, remote user, forks|inventory = inventory/hosts.yml\nremote_user = ansible\nforks = 20|' ansible.cfg
run_logged "$SETUP_LOG" ctl "ansible web -b -m ansible.builtin.user -a 'name=deploy shell=/bin/bash'"
