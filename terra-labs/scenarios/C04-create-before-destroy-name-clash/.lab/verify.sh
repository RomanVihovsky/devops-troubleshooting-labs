d=stacks/api
one_green() {
  local ids; ids=$(docker ps -q --filter label=app=api)
  [ "$(echo "$ids" | grep -c .)" = 1 ] &&
    docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$ids" | grep -qx 'APP_COLOR=green' &&
    docker inspect -f '{{json .NetworkSettings.Networks}}' "$ids" | jq -e '."tfl-api-net".Aliases | index("api")' >/dev/null
}
still_cbd() {
  ci_init $d && ci_tf $d plan -input=false -no-color -var color=red > "$CI/cbd.out" 2>&1
  cat "$CI/cbd.out" >> "$VERIFY_LOG"
  grep -q 'create replacement and then destroy' "$CI/cbd.out"
}
check "one api container: APP_COLOR=green, alias api on tfl-api-net" one_green
check "a color change is still create-before-destroy" still_cbd
check "CI plan of stacks/api shows no changes" plan_clean $d
verdict
