source "$SCN/.lab/facts.sh"
check "the image that broke api" answered bad_image "$(q04_bad)"
check "the last image that worked" answered last_good_image "$(q04_good)"
check "the missing setting" answered missing_setting SESSION_SECRET
check "the exit code" answered exit_code "$(q04_exit)"
check "nothing was changed (still on the broken release)" test "$(kx -n incident get deploy api -o jsonpath='{.spec.template.spec.containers[0].image}')" = "$(q04_bad)"
verdict
