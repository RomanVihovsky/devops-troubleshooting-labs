printf -- '- name: Web node\n  hosts: web\n  become: true\n  roles:\n    - shop\n' > site.yml
ap site.yml
ws_commit "shop on nginx_base"
cp "$SCN/files/site.yml" site.yml
ws_commit "api on the same nodes" "api team"
ap site.yml
