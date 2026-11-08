JQ_V='def v: if type == "object" and has("__ansible_unsafe") then .__ansible_unsafe else . end;'
inv_q() { jq -r "$JQ_V $1" "$CI/.lab-inv.json" 2>/dev/null; }
ctl_ci "ansible-inventory --list" > "$CI/.lab-inv.json" 2>> "$VERIFY_LOG"
by_name() { [ "$(inv_q '._meta.hostvars | keys | sort | join(" ")')" = "shop-db-1 shop-web-1 shop-web-2" ]; }
private_ips() {
  [ "$(inv_q '._meta.hostvars | to_entries | map("\(.key)=\(.value.ansible_host | v)") | sort | join(" ")')" = \
    "shop-db-1=10.78.0.21 shop-web-1=10.78.0.11 shop-web-2=10.78.0.12" ]
}
from_ec2() { inv_q '[._meta.hostvars[] | has("instance_id")] | all' | grep -qx true; }
hkc_on() {
  ctl_ci "ansible-config dump -t base" | grep -q '^HOST_KEY_CHECKING(.*) = True' &&
    ! ws_has 'StrictHostKeyChecking[= ]+no' && ! ws_has 'host_key_checking[ :=]+(false|False|no)'
}

check "the inventory names hosts by their Name tag (shop-db-1 shop-web-1 shop-web-2)" by_name
check "ansible_host = the instances' private IPs" private_ips
check "the inventory still comes from EC2 (instance_id hostvars)" from_ec2
check "site.yml applies on every host" applies site.yml
check "host_vars/shop-db-1.yml applies: shop-db-1 is the primary" eval 'nx db1 "cat /etc/acme-db-role" | grep -qx primary'
check "host key checking is still on" hkc_on
check "site.yml converges (check mode: no changes)" converged site.yml
verdict
