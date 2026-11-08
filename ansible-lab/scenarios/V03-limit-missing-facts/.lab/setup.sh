ap site.yml
ws_commit "web + db"
mkdir -p ci && printf '#!/bin/sh\n# web pipeline - web tier only (faster)\nexec ansible-playbook site.yml --limit web "$@"\n' > ci/deploy-web.sh && chmod +x ci/deploy-web.sh
ws_commit "ci: web-only deploys" "CI team"
nx web1 "rm -f /etc/acme/db.conf"
