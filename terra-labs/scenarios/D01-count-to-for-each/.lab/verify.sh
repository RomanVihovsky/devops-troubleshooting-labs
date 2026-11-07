all_same() { for s in eu-1 eu-2 us-1 us-2 ap-1 ap-2; do same_ctr "tfl-web-$s" || return 1; done; }
check "state is keyed by site (docker_container.web[\"eu-1\"] ...)" in_state web 'docker_container.web["eu-1"]'
check "all six containers are the originals" all_same
check "CI plan of web/ shows no changes" plan_clean web
verdict
