## Hint 1
Start where nginx tells you: `sudo nginx -t`, `systemctl status nginx`, `journalctl -u nginx`.
Fix one thing, then test again - there are several layers.
## Hint 2
Once it starts: request the asset (`curl -i localhost/assets/app.css`) and read
`/var/log/nginx/error.log`. Then load-test:
`seq 50 | xargs -P50 -I{} curl -s -o /dev/null -w '%{http_code}\n' --max-time 2 localhost/ | sort | uniq -c`
## Hint 3
The tuning touched: the site config (syntax), file permissions of the assets, and
`systemctl cat nginx` (a drop-in with a very low limit) + `/etc/nginx/nginx.conf`. Check
`cat /proc/$(pgrep -o nginx)/limits`.
