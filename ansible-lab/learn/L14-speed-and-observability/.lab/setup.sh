# the network team's resolver change: sshd on the nodes does reverse DNS against a dead server
for n in web1 web2; do
  nx $n 'echo "UseDNS yes" > /etc/ssh/sshd_config.d/10-dns.conf
         printf "nameserver 10.78.0.250\noptions timeout:1 attempts:1\n" > /etc/resolv.conf
         systemctl reload ssh 2>/dev/null || systemctl reload sshd'
done
