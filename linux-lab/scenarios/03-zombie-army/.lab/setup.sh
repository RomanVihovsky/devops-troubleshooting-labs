sxi <<'S'
mkdir -p /opt/report-worker
cat > /opt/report-worker/worker.py <<'A'
# report-worker: forks a child per report job
import configparser, os, signal, time
cfg = configparser.ConfigParser()
cfg.read("/etc/report-worker.conf")
reap = cfg.getboolean("worker", "reap_children", fallback=True)
if reap:
    signal.signal(signal.SIGCHLD, signal.SIG_IGN)   # kernel reaps exited children for us
jobs = 0
while True:
    if reap or jobs < 400:
        if os.fork() == 0:
            os._exit(0)                              # "render report"
        jobs += 1
    time.sleep(0.1)
A
cat > /etc/report-worker.conf <<'A'
[worker]
threads = 4
# keep finished children around for post-mortem debugging (INC-2207)
reap_children = no
A
cat > /etc/systemd/system/report-worker.service <<'U'
[Unit]
Description=Report rendering worker

[Service]
ExecStart=/usr/bin/python3 /opt/report-worker/worker.py
Restart=always

[Install]
WantedBy=multi-user.target
U
systemctl daemon-reload && systemctl enable --now report-worker
S
retry 60 sx '[ $(ps -eo state= | grep -c Z) -ge 200 ]'
