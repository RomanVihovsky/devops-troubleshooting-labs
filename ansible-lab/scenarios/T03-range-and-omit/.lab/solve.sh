sed -i 's/{{ range(1, workers_count + 1) }}/{{ range(1, workers_count + 1) | list }}/; s/{{ item.owner }}/{{ item.owner | default(omit) }}/' roles/workers/tasks/main.yml
sed -i 's/, owner: "{{ omit }}"}   # owner: whoever runs the deploy/}   # no owner: whoever runs the deploy/' group_vars/all.yml
ap site.yml
