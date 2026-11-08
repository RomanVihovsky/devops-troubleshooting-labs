cat > requirements.yml <<'YML'
collections:
  - name: /opt/collections/community-general-14.0.0.tar.gz
    type: file
  - name: /opt/collections/ansible-posix-2.2.2.tar.gz
    type: file
  - name: /opt/collections/community-library_inventory_filtering_v1-1.1.5.tar.gz
    type: file
roles:
  - name: acme.logrotate
    src: https://git.acme.example/platform/ansible-role-logrotate.git
    scm: git
    version: v1.0.0
YML
run_logged "$SETUP_LOG" ctl "ansible-galaxy install -r requirements.yml"
ap site.yml
