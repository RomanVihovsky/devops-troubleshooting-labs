nx db1 "mkdir -p /var/lib/acme"; nx app1 "mkdir -p /opt/app"; nx app2 "mkdir -p /opt/app"
ap site.yml
ws_commit "rolling deploy with migrations"
sed -i 's/3.1.0/3.2.0/' group_vars/all.yml
ws_commit "release 3.2.0" "release manager"
ap site.yml
