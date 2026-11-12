# minReplicas 2; a shorter scale-down window so it settles in ~1 min instead of 5 (the window remembers "5")
kx -n api patch hpa api --type merge -p '{"spec":{"minReplicas":2,"behavior":{"scaleDown":{"stabilizationWindowSeconds":60}}}}' >/dev/null
