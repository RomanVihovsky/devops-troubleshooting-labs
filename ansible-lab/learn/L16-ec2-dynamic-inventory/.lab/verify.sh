# unwrap 2.22's {"__ansible_unsafe": ...} markers in ansible-inventory --list output
JQ_V='def v: if type == "object" and has("__ansible_unsafe") then .__ansible_unsafe else . end;'
inv_list() { ctl_ci "ansible-inventory --list" > "$CI/.lab-inv.json" 2> "$CI/.lab-inv.err"; }
inv_q() { jq -r "$JQ_V $1" "$CI/.lab-inv.json" 2>/dev/null; }
group_is() { [ "$(inv_q "[.$1.hosts // [] | .[]] | sort | join(\" \")")" = "$2" ]; }
hosts_are() { [ "$(inv_q '._meta.hostvars | keys | sort | join(" ")')" = "$1" ]; }
private_ips() {
  [ "$(inv_q '._meta.hostvars | to_entries | map("\(.key)=\(.value.ansible_host | v)") | sort | join(" ")')" = \
    "shop-db-1=10.78.0.21 shop-web-1=10.78.0.11 shop-web-2=10.78.0.12" ]
}
ec2_vars() { inv_q '[._meta.hostvars[] | has("instance_id") and has("ec2_tags")] | all' | grep -qx true; }
no_tag_warnings() { ! grep -qiE "deprecat|reserved name" "$CI/.lab-inv.err"; }
page_has() { http_get "http://$1:8080/" | grep -q "$2"; }

inv_list
check "ansible-inventory (ansible.cfg) lists exactly shop-db-1 shop-web-1 shop-web-2" hosts_are "shop-db-1 shop-web-1 shop-web-2"
check "group web = shop-web-1 shop-web-2, group db = shop-db-1" eval 'group_is web "shop-web-1 shop-web-2" && group_is db "shop-db-1"'
check "ansible_host = the instances' private IPs" private_ips
check "hosts carry EC2 hostvars (instance_id, ec2_tags) - the inventory comes from EC2" ec2_vars
check "no deprecation / reserved-name warnings from the inventory" no_tag_warnings
check "the static CMDB inventory is gone" not test -e "$CI/inventory/hosts.yml"
aws launch shop-web-3 web3 web >> "$VERIFY_LOG" 2>&1
inv_list
check "a new instance (shop-web-3, launched just now) joins group web" group_is web "shop-web-1 shop-web-2 shop-web-3"
check "site.yml configures it" eval 'applies site.yml && page_has web3 "ACME shop 2.3.0 on shop-web-3"'
check "site.yml converges (check mode: no changes)" converged site.yml
aws stop shop-web-3 >> "$VERIFY_LOG" 2>&1
verdict
