python3 - <<'PY'
p = "ee/execution-environment.yml"
s = open(p).read()
s = s.replace("""# TODO: images.base_image -> ansiblelab/ee-base:1
# TODO: dependencies -> python interpreter path, ansible_core + ansible_runner (pip), python: jmespath""", """images:
  base_image:
    name: ansiblelab/ee-base:1

dependencies:
  python_interpreter:
    python_path: /usr/local/bin/python3
  ansible_core:
    package_pip: ansible-core==2.22.0
  ansible_runner:
    package_pip: ansible-runner
  python:
    - jmespath""")
open(p, "w").write(s)
PY
run_logged "$SETUP_LOG" ctl "rm -rf ee/wheels ee/context && cp -r /opt/wheels ee/wheels && cd ee && ansible-builder create"
run_logged "$SETUP_LOG" docker build -q --network none -t acme/ee:1 "$WS/ee/context"
run_logged "$SETUP_LOG" docker run --rm --network "$NET" --user "$(id -u):0" -v "$WS:/runner/project" \
  -v "$SSH_DIR:/runner/.ssh:ro" -w /runner/project acme/ee:1 ansible-playbook site.yml
