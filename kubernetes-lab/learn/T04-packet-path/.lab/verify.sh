source "$SCN/.lab/facts.sh"
check "the node of the web pod" answered web_node "$(f_web_node)"
check "the KUBE-SVC chain of t04/web" answered svc_chain "$(f_svc_chain)"
check "the DNAT target" answered dnat_target "$(f_dnat_target)"
check "vxlan.calico MTU" answered vxlan_mtu "$(f_vxlan_mtu)"
check "VXLAN UDP port" answered vxlan_port "$(f_vxlan_port)"
check "the VXLAN peer (outer destination IP)" answered vxlan_peer "$(f_vxlan_peer)"
verdict
