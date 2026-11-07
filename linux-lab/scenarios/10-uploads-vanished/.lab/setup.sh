sxi <<'S'
mkdir -p /srv/uploads
for i in 1 2 3 4 5 6; do head -c $((20000 + i * 977)) /dev/urandom > /srv/uploads/invoice-2026-11-0$i.pdf; done
cat > /etc/systemd/system/srv-uploads.mount <<'U'
[Unit]
Description=Uploads volume

[Mount]
What=tmpfs
Where=/srv/uploads
Type=tmpfs
Options=size=64m,mode=0755

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload && systemctl enable --now srv-uploads.mount
for f in contract-001.pdf contract-002.pdf logo.png; do head -c 15000 /dev/urandom > /srv/uploads/$f; done
S
remember sums "$(sx 'mkdir -p /mnt/.l && mount --bind / /mnt/.l && cd /mnt/.l/srv/uploads && md5sum invoice-* | sort; cd /; umount /mnt/.l; rmdir /mnt/.l')"
remember old "$(sx 'cd /srv/uploads && md5sum contract-* logo.png | sort')"
