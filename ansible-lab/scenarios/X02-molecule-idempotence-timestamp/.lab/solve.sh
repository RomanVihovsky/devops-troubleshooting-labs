sed -i "1s/.*/# Managed by Ansible - do not edit/" roles/node_report/templates/node-report.txt.j2
run_logged "$SETUP_LOG" ctl "sh ci/molecule.sh"
