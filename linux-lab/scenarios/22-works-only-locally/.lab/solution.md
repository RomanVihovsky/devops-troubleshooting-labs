# Solution - firewall DROP + loopback bind

**Root cause**: two layers.
1. `iptables -A INPUT -p tcp --dport 8090 -j DROP` - packets from other hosts are silently
   dropped -> the client *hangs* (DROP = timeout, REJECT = immediate error).
2. `metrics-api` binds to `127.0.0.1` (`/etc/metrics-api.conf`) - once the firewall is
   fixed, remote connects get *Connection refused*.

**Diagnose**
```
sudo ss -ltnp | grep 8090             # 127.0.0.1:8090  <- loopback only
sudo tcpdump -ni eth0 tcp port 8090   # SYNs arrive, no SYN-ACK
sudo iptables -L INPUT -n -v --line-numbers   # DROP counter increments
```

**Fix**
```
sudo iptables -D INPUT -p tcp --dport 8090 -j DROP      # keep the 9100 rule
sudo sed -i 's/^bind = .*/bind = 0.0.0.0/' /etc/metrics-api.conf
sudo systemctl restart metrics-api
```
(Persist firewall changes with your tool: `iptables-save > /etc/iptables/rules.v4`,
nftables, ufw/firewalld.)

**Interview notes**: work up the layers - is it listening (`ss`) / on which address / is
the packet arriving (`tcpdump`) / host firewall / cloud security group / route back.
Timeout vs refused tells you which layer to look at.
