sxi <<'S'
mkdir -p /etc/app /var/log/app
cat > /etc/app/app.conf <<'A'
# app configuration
mode = staging
workers = 4
A
for i in 1 2 3 4 5; do echo "$(date -Is) audit event $i: config read by deploy" >> /var/log/app/audit.log; done
chattr +i /etc/app/app.conf
chattr +a /var/log/app/audit.log
S
remember audit "$(sx 'md5sum < /var/log/app/audit.log')"
