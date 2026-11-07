deploy_stack
retry 60 svc_converged app_files
# the fault: worker2's NIC MTU lowered
inject worker2 'ip link set eth0 mtu 1400' 'ip link set eth0 mtu 1500'
# emulation detail: disable TSO/GSO on the senders so oversized frames are really
# put on the virtual wire (on real hardware a 1500-byte frame is always 1500 bytes)
for n in manager1 worker1; do
  inject "$n" 'ethtool -K eth0 tso off gso off tx-udp_tnl-segmentation off tx-udp_tnl-csum-segmentation off 2>/dev/null; true' \
              'ethtool -K eth0 tso on gso on tx-udp_tnl-segmentation on tx-udp_tnl-csum-segmentation on 2>/dev/null; true'
done
