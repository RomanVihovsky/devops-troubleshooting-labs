# S02: node labels are shared - remove what setup (or a student) added
for n in $(cluster_nodes); do kx label node "$n" disk- disktype- >/dev/null 2>&1; done
true
