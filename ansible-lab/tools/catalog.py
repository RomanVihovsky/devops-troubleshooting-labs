#!/usr/bin/env python3
# usage: python3 tools/catalog.py .   (regenerates docs/CATALOG.md from the labs' own files)
"""Generate docs/CATALOG.md from the labs' own files (scenario.yaml, ticket.md, solution.md, verify.sh)."""
import os, re, sys

root = sys.argv[1] if len(sys.argv) > 1 else "."


def meta(d):
    m = {}
    for line in open(os.path.join(d, "scenario.yaml")):
        if ":" in line:
            k, v = line.split(":", 1)
            m[k.strip()] = v.strip().strip('"')
    m["ticket"] = open(os.path.join(d, "ticket.md")).readline().lstrip("# ").strip()
    sol = open(os.path.join(d, ".lab/solution.md")).readline().strip()
    m["cause"] = re.sub(r"^# Solution - ?", "", sol)
    m["checks"] = re.findall(r'^check(?:_eventually \d+)? "([^"]+)"',
                             open(os.path.join(d, ".lab/verify.sh")).read(), re.M)
    m["dir"] = os.path.basename(d)
    return m


def labs(sub):
    base = os.path.join(root, sub)
    return [meta(os.path.join(base, d)) for d in sorted(os.listdir(base))
            if os.path.isfile(os.path.join(base, d, "scenario.yaml"))]


learn, inc = labs("learn"), labs("scenarios")
nodes = lambda m: ", ".join(x.strip() for x in m.get("nodes", "[]").strip("[]").split(",") if x.strip()) or "-"
esc = lambda t: t.replace("<", "&lt;").replace(">", "&gt;").replace("|", "\\|")
lvl = lambda m: "•" * int(m.get("level", "1"))
domains = [("I", "Inventory & connection"), ("V", "Variables & precedence"),
           ("T", "Templating & upgrades (2.19-2.24)"), ("R", "Roles & collections"),
           ("E", "Execution & idempotency"), ("S", "Secrets & vault"), ("P", "Platforms & packages"),
           ("X", "Pipeline, testing & execution environments"), ("D", "Event-Driven Ansible (EDA)")]

out = []
w = out.append
w("# ansible-lab - catalog\n")
w("> **Spoilers.** The *Root cause* and *Verified by* columns give the answers away. Play first: `./lab start <id>`.\n")
w("Legend: level `•` easy (5-15 min) · `••` medium (15-25 min) · `•••` hard (25-40 min). *Nodes*: the managed")
w("containers the lab starts (Debian 12: lb1 web1 web3 app1 test1 · Rocky 9: web2 app2 db1).")
w("Every lab is checked by `./lab selftest <id>`: it must verify as FAIL when started and PASS after the reference fix.")
w("This file is generated: `python3 tools/catalog.py .`\n")
w(f"## L - Learn track ({len(learn)})\n")
w("| ID | Lab | Lvl | Nodes | Verified by |")
w("|---|---|---|---|---|")
for m in learn:
    title = m["ticket"].split("·", 1)[-1].strip()
    more = " ..." if len(m["checks"]) > 4 else ""
    w(f"| {m['id']} | {esc(title)} | {lvl(m)} | {nodes(m)} | {esc('; '.join(m['checks'][:4]))}{more} |")
w("")
for code, name in domains:
    rows = [m for m in inc if m["id"].startswith(code)]
    if not rows:
        continue
    w(f"## {code} - {name} ({len(rows)})\n")
    w("| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |")
    w("|---|---|---|---|---|---|")
    for m in rows:
        w(f"| {m['id']} | {esc(m['ticket'])} | {lvl(m)} | {nodes(m)} | {esc(m['cause'])} | {esc('; '.join(m['checks']))} |")
    w("")
w("## Totals\n")
w("| Track | Labs |")
w("|---|---|")
w(f"| Learn | {len(learn)} |")
for code, name in domains:
    w(f"| {code} - {name} | {len([m for m in inc if m['id'].startswith(code)])} |")
w(f"| **All** | **{len(learn) + len(inc)}** |\n")
w("Wave 2 (EDA, cloud inventory, execution control, ansible-test) is marked by `wave: 2` in scenario.yaml -")
w("`./lab selftest wave2`. Practise under pressure: `./lab interview` (3 random incidents, timer, score).\n")
w("## Backlog (see PLAN.md §4)\n")
w("`delegate_facts`, `connection: local` / API-only automation, `ansible-test units` / `integration`, decision")
w("environments (ansible-builder for ansible-rulebook), EDA with Kafka / Alertmanager sources.")
open(os.path.join(root, "docs/CATALOG.md"), "w").write("\n".join(out) + "\n")
print(f"learn={len(learn)} incidents={len(inc)}")
