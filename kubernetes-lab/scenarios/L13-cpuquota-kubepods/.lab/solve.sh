nx k8s-w1 'systemctl set-property kubepods.slice CPUQuota= && rm -f /etc/systemd/system.control/kubepods.slice.d/*CPUQuota* && systemctl daemon-reload' </dev/null
kx -n search rollout restart deploy/search >/dev/null
wait_rollout search deploy/search
