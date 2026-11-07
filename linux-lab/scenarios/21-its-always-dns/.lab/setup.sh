source "$LAB_DIR/lib/api-on-client.sh"; start_client_api
sxi <<'S'
sed -i 's/^hosts:.*/hosts:          files myhostname/' /etc/nsswitch.conf
echo '10.77.0.99   api.internal   # old API VM, INC-1770' >> /etc/hosts
S
