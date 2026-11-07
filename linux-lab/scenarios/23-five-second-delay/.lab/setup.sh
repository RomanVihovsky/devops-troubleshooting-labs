source "$LAB_DIR/lib/api-on-client.sh"; start_client_api
# the "old DNS server": an address that silently swallows queries
docker exec lnx-dns sh -c 'ip addr add 10.77.0.54/24 dev eth0 && iptables -I INPUT -d 10.77.0.54 -j DROP'
sxi <<'S'
cat > /etc/resolv.conf <<'A'
# managed by netconfig (migration 2026-10)
nameserver 10.77.0.54
nameserver 10.77.0.53
A
S
