sxi <<'S'
mkdir -p /opt/thumbnailer
cat > /opt/thumbnailer/worker.py <<'A'
# thumbnail worker: keeps a 20 MB working set and churns through 2 MB "images"
import time
working_set = bytearray(20 * 1024 * 1024)
for i in range(0, len(working_set), 4096):
    working_set[i] = 1
while True:
    img = bytearray(2 * 1024 * 1024)
    for i in range(0, len(img), 4096):
        img[i] = 1
    del img
    time.sleep(0.01)
A
cat > /opt/thumbnailer/run.sh <<'A'
#!/bin/bash
# thumbnailer: 4 workers
for i in 1 2 3 4; do python3 /opt/thumbnailer/worker.py & done
wait
A
chmod 755 /opt/thumbnailer/run.sh
cat > /etc/systemd/system/thumbnailer.service <<'U'
[Unit]
Description=Thumbnail rendering workers

[Service]
ExecStart=/opt/thumbnailer/run.sh
Restart=always
# right-sizing PR #311: "it only needs ~50 MB"
MemoryHigh=48M

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload
systemctl enable --now thumbnailer.service
S
retry 40 sx "[ \$(ps -eo state= | grep -c D) -ge 2 ]"
