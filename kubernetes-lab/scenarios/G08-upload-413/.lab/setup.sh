# G08: a buffering middleware with maxRequestBodyBytes 1 MiB in front of an app that takes 64 MiB
kns media
ka -f media.yaml
wait_rollout media deploy/media
up() { head -c "$1" /dev/zero | curl -s -o /dev/null -w '%{http_code}' --max-time 30 -H 'Host: media.lab' --data-binary @- http://192.168.56.200/upload; }
is413() { [ "$(up 2097152)" = 413 ]; }
retry 60 is413 || die "no 413"
