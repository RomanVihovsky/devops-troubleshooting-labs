sxi <<'S'
cat > /etc/sudoers.d/deploy.conf <<'A'
# deploy may restart nginx (CHG-2231)
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx
A
chmod 0440 /etc/sudoers.d/deploy.conf
S
