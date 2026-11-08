#!/usr/bin/env bash
# The "EDA activation" (what EDA controller runs in a decision environment): one rulebook from a project
# checkout, restarted when it exits. Settings come from /srv/eda/activation.env (written by ./lab):
#   PROJECT=/work|/ci   RULEBOOK=rulebooks/x.yml   INVENTORY=inventory/hosts.yml
# `./lab eda restart` (= docker restart ans-eda) re-reads them.
load() {
  # shellcheck disable=SC1091
  source /srv/eda/activation.env
  cd "$PROJECT" || return 1
  # run_playbook runs ansible-playbook through ansible-runner in a private data dir: point it at the project's config
  export ANSIBLE_CONFIG="$PROJECT/ansible.cfg"
}
while true; do
  if load; then
    echo "[activation] $(date -u +%FT%TZ) start: ansible-rulebook --rulebook $RULEBOOK -i $INVENTORY (project $PROJECT)"
    ansible-rulebook --rulebook "$RULEBOOK" -i "$INVENTORY" -v
    echo "[activation] $(date -u +%FT%TZ) ansible-rulebook exited rc=$? - restarting in 5 s"
  else
    echo "[activation] project $PROJECT not available - retrying in 5 s"
  fi
  sleep 5
done
