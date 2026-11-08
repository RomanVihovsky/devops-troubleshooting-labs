sed -i "s/^port:/web_port:/" roles/web/defaults/main.yml
sed -i "s/^port:/metrics_port:/" roles/metrics/vars/main.yml
for r in web metrics; do sed -i "s/{{ port }}/{{ ${r}_port }}/" roles/$r/tasks/main.yml; done
ap site.yml
