# Works on localhost, not from other hosts
**LNX-122** · P1 · Reporter: monitoring team

`metrics-api` on srv listens on port 8090. On srv, `curl localhost:8090/` works. From
the monitoring host (`./lab sh client`), `curl http://10.77.0.10:8090/` just hangs.

Security requirement: the node exporter on port **9100** must stay unreachable from
other hosts.

**Test**: from client, `curl http://10.77.0.10:8090/` answers; port 9100 on srv is still
**not** reachable from client.
