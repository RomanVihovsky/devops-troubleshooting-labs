echo 'appserver_config: /etc/acme/appserver.ini' > roles/appserver/vars/main.yml
printf 'appserver_workers: 2\nappserver_timeout: 30\n' > roles/appserver/defaults/main.yml
ap site.yml
