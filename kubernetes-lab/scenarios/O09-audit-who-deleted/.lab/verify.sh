w=$(recall o09_when)
minutes=""; for o in -60 0 60; do minutes="$minutes $(date -u -d "@$((w + o))" +%H:%M)"; done
back() {
  [ "$(kx -n checkout get configmap feature-flags -o jsonpath='{.data.new_checkout}/{.data.express_shipping}/{.data.gift_wrap}' 2>/dev/null)" = "true/true/false" ]
}
# shellcheck disable=SC2086
check "who deleted it" answered user carol
check "when (UTC, HH:MM)" answered deleted_at $minutes
check "with which client" answered client cleanup-cron cleanup-cron/1.2
check "feature-flags is back with its flags" back
verdict
