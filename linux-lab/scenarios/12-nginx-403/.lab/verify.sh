check "curl localhost/ returns the shop page" sx 'curl -fs localhost/ | grep -q "Welcome to the Shop"'
check "nothing under /srv/www is world-writable" sx '[ -z "$(find /srv/www -perm -o+w)" ]'
verdict
