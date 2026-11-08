sed -i \
  -e "s/when: \"{{ item.enabled }}\"/when: item.enabled/" \
  -e "s/when: \"'{{ inventory_hostname }}' in groups\['prod'\]\"/when: inventory_hostname in groups['prod']/" \
  roles/baseline/tasks/main.yml
grep -q "when: inventory_hostname in groups" roles/baseline/tasks/main.yml
ap site.yml
