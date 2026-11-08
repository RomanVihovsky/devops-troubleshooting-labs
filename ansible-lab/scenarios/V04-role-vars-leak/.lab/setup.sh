printf -- '- name: Web node\n  hosts: web\n  become: true\n  roles:\n    - web\n' > site.yml
ap site.yml
ws_commit "web role"
cp "$SCN/files/site.yml" site.yml
ws_commit "observability: metrics endpoint on every web node" "Observability team"
ap site.yml
