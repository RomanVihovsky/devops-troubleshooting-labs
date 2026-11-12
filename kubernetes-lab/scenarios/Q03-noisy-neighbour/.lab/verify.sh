source "$SCN/.lab/facts.sh"
all_run() { [ "$(kx -n tenants get pods --field-selector=status.phase=Running --no-headers | wc -l)" = 5 ]; }
check "the noisy neighbour" answered pod "$(q03_pod)" "$(q03_deploy)" "deployment/$(q03_deploy)" "tenants/$(q03_pod)"
check "all 5 tenant pods still run" all_run
verdict
