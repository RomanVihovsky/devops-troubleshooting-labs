sxi <<'S'
mkdir -p /opt/queue-worker /data/uploads
cat > /opt/queue-worker/worker.py <<'A'
# queue-worker: journals every message to /data/queue.journal
import time
j = open("/data/queue.journal", "a")
chunk = "M" * (1024 * 1024 - 1) + "\n"
for _ in range(56):                     # replay backlog after start
    j.write(chunk)
j.flush()
n = 0
while True:
    n += 1
    j.write(f"{time.time()} msg {n}\n"); j.flush()
    time.sleep(1)
A
cat > /etc/systemd/system/queue-worker.service <<'U'
[Unit]
Description=Queue worker

[Service]
ExecStart=/usr/bin/python3 /opt/queue-worker/worker.py
Restart=always

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload && systemctl enable --now queue-worker
for i in $(seq 30); do [ "$(stat -c %s /data/queue.journal 2>/dev/null || echo 0)" -gt 50000000 ] && break; sleep 1; done
dd if=/dev/zero of=/data/uploads/batch-0412.bin bs=1M count=6 status=none 2>/dev/null || true
rm -f /data/queue.journal                 # "cleanup"
S
remember pid "$(mainpid queue-worker)"
