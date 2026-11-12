source "$SCN/.lab/facts.sh"
cat > answers.yaml <<YML
web_node: $(f_web_node)
svc_chain: $(f_svc_chain)
dnat_target: "$(f_dnat_target)"
vxlan_mtu: $(f_vxlan_mtu)
vxlan_port: $(f_vxlan_port)
vxlan_peer: $(f_vxlan_peer)
YML
