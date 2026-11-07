dk node update --label-add disktype=ssd worker2 >/dev/null
dk node update --label-add disktype=hdd worker1 >/dev/null
deploy_stack
