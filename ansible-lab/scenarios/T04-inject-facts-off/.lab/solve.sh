for f in roles/node_info/tasks/main.yml roles/node_info/templates/node.json.j2; do
  sed -i -E \
    -e 's/ansible_(os_family|hostname|distribution_major_version|distribution|processor_vcpus|python_version)\b/ansible_facts['"'"'\1'"'"']/g' "$f"
done
sed -i "s/ansible_facts\['python_version'\] | default('n\/a')/ansible_facts['python_version']/" roles/node_info/templates/node.json.j2
ap site.yml
