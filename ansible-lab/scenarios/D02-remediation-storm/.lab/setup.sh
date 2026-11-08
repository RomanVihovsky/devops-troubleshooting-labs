ap site.yml
ws_commit "web tier: nginx + shop page" "Sam (SRE)"
eda_up rulebooks/web.yml
# Tuesday 02:10: a flapping check - one alert every 15 s (compressed here), every one remediated
nx web1 "systemctl stop nginx"
for _ in 1 2 3 4 5 6; do eda_post "$(cat docs/alerts/nginx-down.json)"; done
retry 90 eval '[ "$(docker logs ans-eda 2>&1 | grep -c "TASK \[Restart nginx\]")" -ge 6 ]' || die "the storm did not happen in setup"
retry 30 svc_active web1 nginx
