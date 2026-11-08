ap site.yml
mkdir -p ci && printf '#!/bin/sh\n# release job: app only, no base packages\nset -eu\nexec ansible-playbook site.yml --tags deploy "$@"\n' > ci/release.sh && chmod +x ci/release.sh
ws_commit "app tier + release job"
sed -i 's/1.4.0/1.5.0/' group_vars/all.yml
ws_commit "release 1.5.0" "app team"
run_logged "$SETUP_LOG" ctl "sh ci/release.sh"
