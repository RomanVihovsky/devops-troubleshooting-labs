docker rmi -f acme/ee:1 acme/ee:2 acme/ee:dev >/dev/null 2>&1 || true
ws_commit "ee definition + catalog play"
run_logged "$SETUP_LOG" ctl "rm -rf ee/wheels ee/context && cp -r /opt/wheels ee/wheels && cd ee && ansible-builder create"
run_logged "$SETUP_LOG" docker build -q --network none -t acme/ee:1 "$WS/ee/context"
remember ee1_id "$(docker image inspect -f '{{.Id}}' acme/ee:1)"
sed -i 's/^    package_pip: ansible-runner$/    package_pip: ansible-runner\n  python:\n    - jmespath            # community.general.json_query (OPS-335)/' ee/execution-environment.yml
ws_commit "ee: jmespath for json_query" "platform team"
cat >> site.yml <<'YML'

    - name: Public services
      ansible.builtin.copy:
        dest: /etc/acme/services.txt
        content: "{{ catalog | community.general.json_query('services[?public].name') | join(',') }}\n"
        mode: "0644"
YML
ws_commit "catalog: list public services" "web team"
rm -rf ee/wheels ee/context
run_logged "$SETUP_LOG" docker run --rm --network "$NET" --user "$(id -u):0" -v "$WS:/runner/project" \
  -v "$SSH_DIR:/runner/.ssh:ro" -w /runner/project acme/ee:1 ansible-playbook site.yml || true
