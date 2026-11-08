ap site.yml
ws_commit "node_info role"
lab_setenv ANSIBLE_INJECT_FACT_VARS False
mkdir -p ci && printf '#!/bin/sh\n# 2.24 readiness (PLAT-40)\nset -eu\nexport ANSIBLE_INJECT_FACT_VARS=False\nexec ansible-playbook site.yml "$@"\n' > ci/pipeline.sh && chmod +x ci/pipeline.sh
ws_commit "ci: preview the 2.24 fact injection default" "Platform team"
nx web1 "rm -f /etc/acme/node.json"; nx web2 "rm -f /etc/acme/node.json"   # CMDB re-sync wiped the records
ap site.yml || true
