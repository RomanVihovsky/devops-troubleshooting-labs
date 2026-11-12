sed -i 's|"/script/report.sh"|"/scripts/report.sh"|' report.yaml
kx -n batch delete job nightly-report >/dev/null
kx apply -f report.yaml >/dev/null
kx -n batch wait --for=condition=complete job/nightly-report --timeout=120s >/dev/null || true
