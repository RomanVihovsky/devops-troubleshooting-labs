sx 'pid=$(systemctl show -p MainPID --value queue-worker); for fd in /proc/$pid/fd/*; do
      [ "$(readlink "$fd")" = "/data/queue.journal (deleted)" ] && : > "$fd"; done'
