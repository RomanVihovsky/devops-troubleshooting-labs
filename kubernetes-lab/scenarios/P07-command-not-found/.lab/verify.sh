same_image() { [ "$(kx -n reports get deploy reports -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)" = registry.lab:5000/lab/labapp:1.4 ]; }
check_eventually 120 "reports rollout complete, all replicas Ready" deploy_ready reports reports
check "same image (registry.lab:5000/lab/labapp:1.4)" same_image
verdict
