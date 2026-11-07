sxi <<'S'
mkdir -p /srv/tools-src /opt/tools /var/lib/rotate
cat > /srv/tools-src/rotate-keys.sh <<'A'
#!/bin/bash
# rotate application keys (demo)
date -Is > /var/lib/rotate/last-run
echo "keys rotated"
A
chmod 755 /srv/tools-src/rotate-keys.sh
cat > /etc/systemd/system/opt-tools.mount <<'U'
[Unit]
Description=Shared ops tools

[Mount]
What=/srv/tools-src
Where=/opt/tools
Type=none
Options=bind,noexec,nosuid,nodev

[Install]
WantedBy=multi-user.target
U
cat > /etc/systemd/system/rotate-keys.service <<'U'
[Unit]
Description=Rotate application keys
RequiresMountsFor=/opt/tools

[Service]
Type=oneshot
ExecStart=/opt/tools/rotate-keys.sh
U
systemctl daemon-reload && systemctl enable --now opt-tools.mount
systemctl start rotate-keys.service || true
S
