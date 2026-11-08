run_logged "$SETUP_LOG" ctl "rm -rf ee/wheels ee/context && cp -r /opt/wheels ee/wheels && cd ee && ansible-builder create"
run_logged "$SETUP_LOG" docker build -q --network none -t acme/ee:2 "$WS/ee/context"
echo acme/ee:2 > ci/ee-image
rm -rf ee/wheels ee/context
run_logged "$SETUP_LOG" docker run --rm --network "$NET" --user "$(id -u):0" -v "$WS:/runner/project" \
  -v "$SSH_DIR:/runner/.ssh:ro" -w /runner/project acme/ee:2 ansible-playbook site.yml
