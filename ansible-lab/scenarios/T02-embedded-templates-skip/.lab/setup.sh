ap site.yml
ws_commit "baseline role"
mkdir -p ci
cat > ci/pipeline.sh <<'SH'
#!/bin/sh
# CI deploy - runs with the ansible-core 2.23 preview defaults (PLAT-31)
set -eu
export ANSIBLE_ALLOW_EMBEDDED_TEMPLATES=False
exec ansible-playbook site.yml "$@"
SH
chmod +x ci/pipeline.sh
ws_commit "ci: run with the 2.23 preview defaults" "Platform team"
lab_setenv ANSIBLE_ALLOW_EMBEDDED_TEMPLATES False
nx web1 "rm -f /etc/acme/prod-hardening"        # prod node rebuilt last night
ap site.yml
