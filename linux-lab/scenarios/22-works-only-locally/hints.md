## Hint 1
"Hangs" (timeout) and "connection refused" mean different things. On srv: which address
is the service bound to? `sudo ss -ltnp | grep 8090`.
## Hint 2
Watch the packets arrive on srv while curling from client: `sudo tcpdump -ni eth0 tcp port 8090`.
Do they arrive? Does anything answer? Check the host firewall: `sudo iptables -S` / `iptables -L -n -v`.
## Hint 3
Two layers: a firewall DROP rule for 8090 (remove only that one) **and** the app binding
to 127.0.0.1 (`/etc/metrics-api.conf`, then restart). Re-test from client after each step.
