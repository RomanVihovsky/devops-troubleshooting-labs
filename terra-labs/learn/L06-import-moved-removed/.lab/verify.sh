d=stacks/legacy
flag_ok() {   # flag_ok <name> <value>: same value, never overwritten (version 1)
  [ "$(aws ssm get-parameter --name "/legacy/flags/$1" --query '[Parameter.Value,Parameter.Version]' --output text)" = "$2	1" ]
}
flags_in_state() { for k in checkout search recs; do state_has_re $d "^aws_ssm_parameter\\.[a-z_]+\\[\"$k\"\\]$" || return 1; done; }
same_role() { [ "$(aws iam get-role --role-name legacy-reporting --query Role.RoleId --output text 2>/dev/null)" = "$(recall role_id)" ]; }
check "flags checkout/search/recs are in state (for_each)" flags_in_state
check "flag values untouched (on/off/on, never rewritten)" eval 'flag_ok checkout on && flag_ok search off && flag_ok recs on'
check "role legacy-reporting is in state" state_has_re $d '^aws_iam_role\.'
check "it is still the same role (not recreated)" same_role
check "bucket acme-legacy-reports is no longer in state" not state_has_re $d '^aws_s3_bucket(_versioning)?\.reports$'
check "... but still exists with its files" object_exists acme-legacy-reports 2026/10.csv
check "CI plan of stacks/legacy shows no changes" plan_clean $d
verdict
