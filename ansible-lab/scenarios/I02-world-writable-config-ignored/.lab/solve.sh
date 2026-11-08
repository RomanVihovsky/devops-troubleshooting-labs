sed -i 's|^# 2026-10: the runner user differs.*|# never world-writable: ansible.cfg in a world-writable cwd is ignored (security)|; s|^chmod -R 0777 "$build"|chmod -R go-w "$build"|' ci/deploy.sh
