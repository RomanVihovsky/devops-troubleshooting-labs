names() {
  kx -n market run "lab-probe-$RANDOM" --rm -i --restart=Never --quiet --image="$BUSYBOX_IMAGE" --labels="$LAB_LABEL=$LAB_ID" --command -- \
    sh -c 'sleep 2; for i in $(seq 20); do wget -q -O - -T 3 http://web.market.svc/version; echo; done' 2>/dev/null | grep -o '"name": *"[a-z]*"' | sed 's/.*"\([a-z]*\)"$/\1/'
}
# (the attach of kubectl run -i can miss early lines: >= 15 answers seen, none from admin)
all_web() { local n; n=$(names); [ "$(grep -c '^web$' <<<"$n")" -ge 15 ] && ! grep -q '^admin$' <<<"$n"; }
check_eventually 90 "20/20 requests through Service web answered by web" all_web
check "admin has Ready pods" deploy_ready market admin
verdict
