remember answers "$(sxi <<'S'
python3 - <<'P'
import random, collections
random.seed(4711)
ips = [f"{random.choice([23,45,62,81,91,103,145,176,185,198])}.{random.randint(1,254)}.{random.randint(1,254)}.{random.randint(1,254)}" for _ in range(400)]
attacker = "203.0.113.47"
paths = ["/", "/shop", "/cart", "/api/items", "/static/app.js", "/static/app.css", "/login", "/search?q=boots"]
uas = ['Mozilla/5.0 (X11; Linux x86_64) Firefox/131.0', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/130.0',
       'curl/8.5.0', 'Googlebot/2.1 (+http://www.google.com/bot.html)']
lines = []
def add(ip, minute, path, status):
    h, m = divmod(minute, 60)
    lines.append((minute, f'{ip} - - [03/Nov/2026:{h:02d}:{m:02d}:{random.randint(0,59):02d} +0000] "GET {path} HTTP/1.1" {status} {random.randint(150,9000)} "-" "{random.choice(uas)}"'))
for _ in range(34000):
    add(random.choice(ips), random.randint(0, 1439), random.choice(paths), random.choice([200]*18 + [301, 404]))
for _ in range(900):                                   # the scanner
    add(attacker, random.randint(120, 300), random.choice(["/.env", "/admin.php", "/phpmyadmin/", "/.git/config", "/backup.zip"]), 404)
wp = random.sample(ips, 37)
for ip in wp:
    for _ in range(random.randint(1, 6)):
        add(ip, random.randint(0, 1439), "/wp-login.php", 404)
for _ in range(1500):                                  # traffic spike
    add(random.choice(ips), 14 * 60 + 37, random.choice(paths), 200)
lines.sort()
with open("/var/log/nginx/access.log.1", "w") as f:
    f.write("\n".join(l for _, l in lines) + "\n")
st = collections.Counter(); wpips = set(); mins = collections.Counter()
for _, l in lines:
    p = l.split()
    if p[8] == "404": st[p[0]] += 1
    if p[6] == "/wp-login.php": wpips.add(p[0])
    mins[p[3][13:18]] += 1
print(f"1: {st.most_common(1)[0][0]}\n2: {len(wpips)}\n3: {mins.most_common(1)[0][0]}")
P
S
)"
sx 'chown root:adm /var/log/nginx/access.log.1 && chmod 640 /var/log/nginx/access.log.1 && usermod -aG adm admin'
