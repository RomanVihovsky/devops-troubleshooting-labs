## Hint 1
Who owns the socket? `sudo ss -ltnp 'sport = :80'` (or `sudo lsof -i :80`, `fuser -v 80/tcp`).
Look carefully at the PID.
## Hint 2
PID 1 is systemd. systemd can listen on a port itself and start a service only when a
connection arrives (**socket activation**). `systemctl list-sockets`.
## Hint 3
Stop and disable the `.socket` unit (stopping the `.service` is not enough), then start nginx.
