sed -i '/order: sorted/d; s/^  max_fail_percentage: 50 .*/  max_fail_percentage: 0       # any failed node in a batch stops the rollout ("must be exceeded": 1 of 2 = 50 % is not > 50)/' deploy.yml
grep -q 'max_fail_percentage: 0' deploy.yml
ap deploy.yml -e shop_release=4.2.0
