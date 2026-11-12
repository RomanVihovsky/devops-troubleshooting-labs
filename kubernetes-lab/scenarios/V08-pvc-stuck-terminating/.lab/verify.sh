gone() { ! kx -n forms get pvc forms-data >/dev/null 2>&1; }
on_v2() { [ "$(kx -n forms get deploy forms -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}')" = forms-data-v2 ]; }
check_eventually 120 "PVC forms-data is gone" gone
check "forms mounts forms-data-v2" on_v2
check_eventually 120 "forms Ready" deploy_ready forms forms
verdict
