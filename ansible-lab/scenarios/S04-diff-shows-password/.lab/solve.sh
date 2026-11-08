sed -i 's|^        mode: "0600"$|        mode: "0600"\n      diff: false   # secrets inside - the PR comment must not show them|' site.yml
grep -q 'diff: false' site.yml
ap site.yml
