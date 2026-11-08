run_logged "$SETUP_LOG" ctl "ansible-galaxy collection install --no-deps -p ./collections /opt/collections/community-general-12.0.0.tar.gz"
ap site.yml
ws_commit "vendor community.general for the air-gapped runner (2024)"
cat >> site.yml <<'YML'
    - name: Rotate app logs
      community.general.logrotate:
        name: acme
        paths:
          - /var/log/acme/*.log
        rotation_period: daily
        rotate_count: 14
        compress: true
        missing_ok: true
        not_if_empty: true
YML
printf 'collections:\n  - name: community.general\n    version: "==14.0.0"   # shipped in the runner image\n' > requirements.yml
ws_commit "logrotate via community.general.logrotate" "web team"
ap site.yml || true
