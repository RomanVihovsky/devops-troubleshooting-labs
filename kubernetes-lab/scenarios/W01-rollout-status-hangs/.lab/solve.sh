kx -n storefront rollout undo deploy/storefront >/dev/null
kx -n storefront patch deploy storefront -p '{"spec":{"progressDeadlineSeconds":300}}' >/dev/null
wait_rollout storefront deploy/storefront 180
