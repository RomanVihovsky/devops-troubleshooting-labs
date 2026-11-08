p1=$(recall pw_alice); p2=$(recall pw_bob)
deploy_log_clean() {
  ctl_ci "sh ci/deploy.sh" > "$CI/.lab-deploy.out" 2>&1 || { cat "$CI/.lab-deploy.out" >> "$VERIFY_LOG"; return 1; }
  ! grep -qF -e "$p1" -e "$p2" "$CI/.lab-deploy.out"
}
json_clean() { ap_json site.yml -v && ! grep -qF -e "$p1" -e "$p2" "$CI/.lab-ap.json"; }
pw_ok() {   # pw_ok <user> <password>: the shadow hash accepts it
  nx web1 "python3 -W ignore -c 'import crypt,spwd,sys; h=spwd.getspnam(sys.argv[1]).sp_pwdp; sys.exit(crypt.crypt(sys.argv[2], h) != h)' $1 '$2'"
}
check "ci/deploy.sh output holds no initial password" deploy_log_clean
check "a JSON-callback run holds no initial password" json_clean
check "alice and bob accept their initial passwords" eval 'pw_ok alice "$p1" && pw_ok bob "$p2"'
check "site.yml converges" converged site.yml
verdict
