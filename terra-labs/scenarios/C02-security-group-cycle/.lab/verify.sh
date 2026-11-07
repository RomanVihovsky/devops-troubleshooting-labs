lb=$(recall sg_lb); app=$(recall sg_app)
ref_rule() {   # ref_rule <group> <egress true|false> <referenced group>
  [ "$(aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$1" \
        --query "length(SecurityGroupRules[?IsEgress==\`$2\` && FromPort==\`8080\` && ReferencedGroupInfo.GroupId=='$3'])" --output text)" = 1 ]
}
same_groups() {
  [ "$(aws ec2 describe-security-groups --filters Name=group-name,Values=lb --query 'SecurityGroups[0].GroupId' --output text)" = "$lb" ] &&
  [ "$(aws ec2 describe-security-groups --filters Name=group-name,Values=app --query 'SecurityGroups[0].GroupId' --output text)" = "$app" ]
}
check "app allows 8080 from the lb group" ref_rule "$app" false "$lb"
check "lb allows egress 8080 to the app group" ref_rule "$lb" true "$app"
check "both security groups are the originals" same_groups
check "CI plan of stacks/edge shows no changes (no cycle)" plan_clean stacks/edge
verdict
