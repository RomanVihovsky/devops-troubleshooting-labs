#!/usr/bin/env python3
# usage: python3 tools/catalog.py .   (regenerates docs/CATALOG.md from the labs' own files)
"""Generate docs/CATALOG.md from the labs' own files (scenario.yaml, ticket.md, solution.md, verify.sh)."""
import os, re, sys
root = sys.argv[1]
def meta(d):
    m = {}
    for line in open(os.path.join(d, "scenario.yaml")):
        if ":" in line:
            k, v = line.split(":", 1); m[k.strip()] = v.strip()
    m["ticket"] = open(os.path.join(d, "ticket.md")).readline().lstrip("# ").strip()
    sol = open(os.path.join(d, ".lab/solution.md")).readline().strip()
    m["cause"] = re.sub(r"^# Solution - ?", "", sol)
    checks = re.findall(r'^check(?:_eventually \d+)? "([^"]+)"', open(os.path.join(d, ".lab/verify.sh")).read(), re.M)
    m["checks"] = checks
    m["dir"] = os.path.basename(d)
    return m
learn = [meta(os.path.join(root, "learn", d)) for d in sorted(os.listdir(os.path.join(root, "learn")))]
inc = [meta(os.path.join(root, "scenarios", d)) for d in sorted(os.listdir(os.path.join(root, "scenarios")))]
needs = lambda m: ", ".join(x.strip() for x in m.get("needs", "[]").strip("[]").split(",") if x.strip()) or "-"
esc = lambda t: t.replace("<", "&lt;").replace(">", "&gt;").replace("|", "\\|")
lvl = lambda m: "•" * int(m.get("level", "1"))
domains = [("S", "State & backends"), ("D", "Drift, import & refactoring"), ("C", "Language & config"),
           ("P", "Providers & init"), ("M", "Modules"), ("G", "Terragrunt 1.x"), ("X", "Pipelines, security & testing")]
out = []
w = out.append
w("# terra-labs - catalog\n")
w("> **Spoilers.** The *Root cause* and *Verify* columns give the answers away. Play first: `./lab start <id>`.\n")
w("Legend: level `•` easy (5-10 min) · `••` medium (10-20 min) · `•••` hard (20-40 min). *Needs*: `moto` = fake AWS")
w("(moto server), `docker` = containers on the host's Docker, `git` = local module registry (`git.acme.example`).")
w("Every lab is checked by `./lab selftest <id>`: it must verify as FAIL when started and PASS after the reference fix.\n")
w(f"## L - Learn track ({len(learn)})\n")
w("| ID | Lab | Lvl | Needs | Verified by |")
w("|---|---|---|---|---|")
for m in learn:
    w(f"| {m['id']} | {m['ticket'].split('·',1)[-1].strip()} | {lvl(m)} | {needs(m)} | {esc('; '.join(m['checks'][:4]))}{' ...' if len(m['checks'])>4 else ''} |")
w("")
tot = {}
for code, name in domains:
    rows = [m for m in inc if m["id"].startswith(code)]
    if not rows: continue
    w(f"## {code} - {name} ({len(rows)})\n")
    w("| ID | Ticket (symptom) | Lvl | Needs | Root cause (spoiler) | Verified by |")
    w("|---|---|---|---|---|---|")
    for m in rows:
        tot[m.get("wave", "1")] = tot.get(m.get("wave", "1"), 0) + 1
        w(f"| {m['id']} | {esc(m['ticket'])} | {lvl(m)} | {needs(m)} | {esc(m['cause'])} | {esc('; '.join(m['checks']))} |")
    w("")
w("## Totals\n")
w("| Track | Labs |")
w("|---|---|")
w(f"| Learn | {len(learn)} |")
for code, name in domains:
    n = len([m for m in inc if m['id'].startswith(code)])
    w(f"| {code} - {name} | {n} |")
w(f"| **All** | **{len(learn) + len(inc)}** |\n")
w("## Backlog (wave 2, see PLAN.md §4)\n")
w("S06 DynamoDB -> S3 lockfile migration · S07 workspace mix-up · D07 timestamp() in triggers · C06 object type")
w("without optional() · C07 nonsensitive() leak · P05 hard-coded profile · P06 module not installed ·")
w("G11 `errors { retry }` for throttling · G12 `exclude` on dependency outputs · G13 destroy scope · G14 plugin")
w("cache race (`TF_PLUGIN_CACHE_DIR` + `run --all`) · X05 committed tfvars secrets · L15 what's new 1.14-1.17 ·")
w("`./lab interview` (3 random tickets, timer, score).")
open(os.path.join(root, "docs/CATALOG.md"), "w").write("\n".join(out) + "\n")
print(f"learn={len(learn)} incidents={len(inc)}")
