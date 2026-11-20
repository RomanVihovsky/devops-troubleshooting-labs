#!/usr/bin/env python3
"""Print the README's lab tables (learn track + incidents by domain) from scenario.yaml / ticket.md.

    python3 tools/tables.py            # markdown on stdout
    python3 tools/tables.py --readme   # rewrite the block between the TABLES markers in README.md
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOMAINS = [("P", "Pods & containers"), ("C", "Configuration"), ("S", "Scheduling"),
           ("R", "Resources & autoscaling"), ("W", "Workload controllers"), ("N", "Services & DNS"),
           ("G", "Ingress & Gateway API"), ("X", "NetworkPolicy & CNI"), ("V", "Storage"), ("A", "Security"),
           ("K", "Control plane & etcd"), ("L", "Nodes & runtime"), ("O", "Cluster operations"),
           ("Q", "Observability & forensics"), ("D", "Delivery: Helm & Argo CD"), ("Y", "Secrets"),
           ("B", "Boss fights (several faults at once)")]


def labs(sub):
    out = []
    base = os.path.join(ROOT, sub)
    for d in sorted(os.listdir(base)):
        y = os.path.join(base, d, "scenario.yaml")
        if not os.path.isfile(y):
            continue
        meta = {}
        for line in open(y):
            m = re.match(r"^(\w+):\s*(.*?)\s*(#.*)?$", line)
            if m:
                meta[m.group(1)] = m.group(2).strip("'\"")
        title = open(os.path.join(base, d, "ticket.md")).readline().lstrip("#").strip()
        title = re.sub(r"^" + re.escape(meta.get("id", "")) + r"\s*·\s*", "", title)
        meta["ticket"] = title.replace("|", "\\|")
        out.append(meta)
    return out


def dots(level):
    return "•" * int(level or 1)


def render():
    lines = ["## Learn track", "", "| ID | Lab | Lvl | Reset |", "|---|---|---|---|"]
    for m in labs("learn"):
        lines.append(f"| {m['id']} | {m['ticket']} | {dots(m.get('level'))} | {m.get('reset', 'ns')} |")
    inc = labs("scenarios")
    lines += ["", f"## Incidents ({len(inc)})", "",
              "Level • one layer, •• the right concept or tool, ••• several layers or internals. Reset is what the "
              "cleanup restores (`ns` seconds, `node` under a minute, `cluster` 1-3 minutes).", ""]
    for letter, name in DOMAINS:
        rows = [m for m in inc if m["id"].startswith(letter)]
        if not rows:
            continue
        lines += [f"### {letter} - {name} ({len(rows)})", "", "| ID | Ticket | Lvl | Reset | Wave |", "|---|---|---|---|---|"]
        for m in rows:
            lines.append(f"| {m['id']} | {m['ticket']} | {dots(m.get('level'))} | {m.get('reset', 'ns')} | {m.get('wave', '')} |")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


if __name__ == "__main__":
    text = render()
    if "--readme" in sys.argv:
        p = os.path.join(ROOT, "README.md")
        s = open(p).read()
        a, b = "<!-- TABLES:BEGIN (python3 tools/tables.py --readme) -->", "<!-- TABLES:END -->"
        i, j = s.index(a) + len(a), s.index(b)
        open(p, "w").write(s[:i] + "\n" + text + s[j:])
    else:
        sys.stdout.write(text)
