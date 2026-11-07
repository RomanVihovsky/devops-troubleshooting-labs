sxi <<'S'
mkdir -p /opt/data-indexer
cat > /opt/data-indexer/indexer.py <<'A'
# data-indexer: caches 1 MiB index segments in memory
import os, time, collections
max_items = int(os.environ.get("CACHE_MAX_ITEMS", "50"))    # 0 = unlimited
cache = collections.OrderedDict()
n = 0
while True:
    n += 1
    cache[n] = bytearray(os.urandom(16)) * (1024 * 1024 // 16)   # 1 MiB segment
    if max_items and len(cache) > max_items:
        cache.popitem(last=False)
    if n % 10 == 0:
        print(f"indexed {n} segments, cache={len(cache)}", flush=True)
    time.sleep(0.25)
A
cat > /etc/default/data-indexer <<'A'
# data-indexer settings
INDEX_PATH=/var/lib/data-indexer
CACHE_MAX_ITEMS=0
A
cat > /etc/systemd/system/data-indexer.service <<'U'
[Unit]
Description=Search data indexer

[Service]
EnvironmentFile=/etc/default/data-indexer
ExecStart=/usr/bin/python3 /opt/data-indexer/indexer.py
Restart=always
RestartSec=2
MemoryMax=96M

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload && systemctl enable --now data-indexer
S
retry 60 sh -c "[ \"\$(docker exec lnx-srv systemctl show -p NRestarts --value data-indexer)\" -ge 1 ]"
