# k8s-w3 fails the node baseline audit after its kernel update
**AUD-77** · P3 · Reporter: compliance

`k8s-w3` was rebooted for a kernel update. Since then our node baseline check flags it: `sysctl
net.bridge.bridge-nf-call-iptables` says *No such file or directory*, and `systemd-sysctl` logged errors at
boot. The other workers pass. Workloads look fine today - make the node compliant again, and make sure it
stays compliant after the **next** reboot.

**Test** (it reboots `k8s-w3`): after the reboot, `br_netfilter` is loaded and
`net.bridge.bridge-nf-call-iptables` / `-ip6tables` = 1 and `net.ipv4.ip_forward` = 1 on `k8s-w3`; `k8s-w3` Ready.
