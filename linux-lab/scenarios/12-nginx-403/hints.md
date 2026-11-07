## Hint 1
nginx tells you why: `sudo tail /var/log/nginx/error.log`. Which user do the nginx workers run as?
(`ps -o user,cmd -C nginx`)
## Hint 2
To open a file, a user needs `x` (search) permission on **every directory** in the path.
`namei -l /srv/www/shop/index.html` shows them all at once.
## Hint 3
Test as the worker user: `sudo -u www-data cat /srv/www/shop/index.html`. Give *traverse*
(not write) permission where it's missing.
