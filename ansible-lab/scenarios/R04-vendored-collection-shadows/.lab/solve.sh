git rm -rq collections
rm -rf collections      # leftovers git never tracked still count
sed -i '/^collections_path = /d' ansible.cfg
ap site.yml
