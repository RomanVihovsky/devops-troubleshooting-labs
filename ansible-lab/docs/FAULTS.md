# How the faults are made (and how to build your own)

Every incident replays a **real history**: `setup.sh` runs the team's playbooks against fresh nodes exactly as
they did, commits that history into `workspace/`, then makes the one mistake the ticket is about - in the repo,
on a node, in the git registry or in the CI environment. Nothing is mocked text: lost handler notifications,
duplicated `sshd_config` lines, vault headers, stale images and half-applied configs are genuine.

## Techniques

| Area | Technique | Used by |
|---|---|---|
| Inventory & connection | `node_rebuild` = golden-image rebuild: new host keys, not re-trusted | I01 |
| | CI runner checks the repo out world-writable -> `ansible.cfg` ignored | I02 |
| | inventory group renamed, `group_vars/` file not (plus invalid group characters) | I03 |
| | Python removed from a node ("minimal image"); sudoers hardened (no NOPASSWD); `acl` missing | I04-I06 |
| Variables | a tunable moved into a role's `vars/`; a dict overridden instead of merged; `--limit` in CI; two roles with an unprefixed variable | V01-V04 |
| Templating & upgrades | repo written for 2.16 run on 2.22; **future defaults previewed** with `lab_setenv` (`ANSIBLE_ALLOW_EMBEDDED_TEMPLATES=False` = 2.23, `ANSIBLE_INJECT_FACT_VARS=False` = 2.24) - in the CI env, `./lab sh` and verify | T01-T04 |
| | 2.22 masking vs a pipeline that scrapes stdout; a "cleanup" commit that changes a var's type; `file` lookup of a template | T05-T07 |
| Roles & collections | a failing task right after a notify (notification lost for good) | R01, P03 |
| | `include_role` + tags; `requirements.yml` on `version: main` + an untagged push to the registry; a vendored 12.0.0 collection in the repo; two `meta` dependencies with different params | R02-R05 |
| Execution | commands instead of modules; a `lineinfile` regexp that only matches the commented default; a read skipped in check mode; `async` + `poll: 0`; `run_once` + `serial` | E01-E03, E05, E06 |
| | rolling deploy without `serial`/drain/health gate, judged by curling the LB **during** a bad deploy | E04 |
| Secrets | vault rekeyed with a new vault ID; passwords from a JSON export (not masked); `.vault_pass` committed; `--diff` in a PR bot | S01-S04 |
| Platforms | an apt/apache2 role meets Rocky; a node "re-imaged" with the vendor's repo files (`/root/repos.orig`); `ssh` vs `sshd` | P01-P03 |
| Pipeline | lint 26 `production` profile on 2021 code; a timestamp in a template under molecule; an EE definition changed but the image tag never bumped; `forks = 1` + per-item package loop + 4x fact gathering | X01-X04 |
| | a module whose docs, argument_spec, shebang and imports disagree - judged by the real `ansible-test sanity` | X05 |
| Wave 2: cloud inventory | moto EC2 instances launched with the **private IPs of real lab nodes**; default `hostnames` (public DNS); a never-expiring inventory cache on the "runner" (`/var/tmp` in the controller) + a stopped instance; the fleet changes *during* verify (stop / launch) | L16, I07, I08 |
| Wave 2: execution control | per-host step durations from `host_vars` (`sleep` stand-ins) make a `strategy: free` race deterministic, verified by a time limit between "split play" and "linear"; a read-modify-write tool with a 2 s window delegated to lb1; real Python 3.9 vs 3.11 differences (`match`, `asyncio.coroutine`) make "bad builds" fail on one OS family | E07-E09 |
| Wave 2: EDA | the activation (`ans-eda`) is pointed at the CI checkout, verify plays monitoring (POSTs alerts), node probes decide: nginx back, other hosts untouched (`ActiveEnterTimestampMonotonic`), restarts counted in the journal | L15, D01, D02 |

## The environment, honestly

| Piece | What it is | Fidelity notes |
|---|---|---|
| Nodes | `ansiblelab/node-debian12:1`, `ansiblelab/node-rocky9:1`: systemd PID 1, sshd, python3, sudo, user `ansible` (key auth, NOPASSWD) | Real systemd units, real sshd (`sshd -T`), real package managers. No kernel tunables (sysctl files are written, not applied), no SELinux |
| Controller | `ansiblelab/ctl:1`: python 3.13, ansible-core 2.22.0, lint/molecule/navigator/builder, collections from `versions.env` | User `ops` with the host user's UID: files in workspace/ stay yours |
| Packages | `ans-repo` (nginx) serves an apt flat repo + a dnf repo built from `MIRROR_*_PKGS` | Only what the labs install is mirrored; `update_cache` works offline |
| Network | `ansiblelab` 10.78.0.0/24, `--internal` | No default route: `ansible_facts['default_ipv4']` is **empty** on the nodes (labs use `all_ipv4_addresses`) |
| Git registry | `https://git.acme.example/...` rewritten to `.state/git/*.git` via `url.insteadOf` in the controller's gitconfig | Real `ansible-galaxy` git installs, tags, pushes |
| EE | `ansible-builder create` in the controller, `docker build --network none` + `docker run --user <uid>:0` on the host (`./lab ee`) | Same image layout as AAP/navigator; navigator itself can't run without a socket - the lab does what it would do |
| CI | `./lab verify` = tar copy of workspace/ to `/ci`, playbooks with the `ansible.posix.json` callback | Untracked files come along (like a runner workspace); `.ansible/` caches don't |
| EDA | `ans-eda`: ansible-rulebook 1.3.2 (Java 21, ansible.eda 2.13.0) running one rulebook from `/work` or `/ci` (`infra/eda/activation.sh`, restarted on exit) | What an activation in EDA controller does, minus the UI: `run_playbook` instead of `run_job_template` |
| Fake AWS | `ans-aws`: moto 5.2.5 (EC2) in memory; `AWS_ENDPOINT_URL` + dummy keys in the runner env (`lab_setenv`) | Instances get public IPs/DNS names that resolve nowhere; moto can't relaunch on a terminated instance's IP (500) |
| Wheelhouse | `cache/pypi/{eda,aws,moto,sanity}`; `/etc/pip.conf` in the controller = no index, `/opt/pypi/sanity` | `ansible-test` per-test venvs install offline; its pip bootstrap script is pre-seeded |

## Things Ansible did that surprised us (they became lab content)

* **2.22 error messages carry the origin** of the offending value (`file:line:col`) - tickets quote them verbatim.
* **Embedded templates are still only a warning in 2.22** (`when: "x == '{{ y }}'"`). With the 2.23 default
  (`ALLOW_EMBEDDED_TEMPLATES=False`) the literal string is compared - the task is **silently skipped**, no
  warning at all. (T02)
* **A command skipped in check mode registers `rc: 0` and an empty `stdout`** on 2.22 - older versions crashed on
  the missing attribute; now the dry run quietly predicts wrong. (E03)
* **Masking is a substring replacement.** A vault password `pass` turns every `password` in the output into
  `$REDACTED$word`. Values from vault and password lookups are masked; values from a `file`/JSON lookup are not.
  (S02, S04, T05)
* `omit` inside a data structure **removes the key** (the task then fails on `item.owner`); `range()` results
  can't be stored. (T03)
* A **`collections/` directory next to the playbook is searched implicitly** - removing it from
  `collections_path` isn't enough, and a half-deleted vendored tree (files git never tracked) still shadows the
  real collection. (R04)
* With `roles:`, a task sees its **own** role's defaults above other roles' defaults - but another role's
  `vars/` still win. Unprefixed variables leak only "sometimes". (V04)
* `ANSIBLE_CONFIG=/dev/null` is rejected ("Unsupported configuration file extension"); use an empty `.cfg`.
* `ansible.cfg` has no inline comments: `forks = 1   # note` is "an invalid value for integer".
* `-e workers_count=4` is a **string**: `workers_count + 1` fails. Use `-e '{"workers_count": 4}'`.
* `port` is a reserved variable name (it is a play keyword) - ansible-lint 26 `var-naming[no-reserved]`. (X01)
* molecule 26 (ansible-compat) refuses a role without `galaxy_info.namespace`.
* `community.general.to_toml` needs `tomlkit` on the controller; `community.general.logrotate` exists since 12.5.0.
* `ansible-vault encrypt_string` with two `default` sources (cfg + CLI) refuses: "vault-ids default,default". (S03)
* **ansible-rulebook**: `run_playbook` runs against the **ruleset's `hosts:`** (`--limit`) - scope the playbook to the
  event's host yourself; an event no rule matches vanishes silently (HTTP 200 for the sender). (L15, D01)
* **amazon.aws 12**: default `hostnames` -> the public DNS name; terminated instances are hidden, **stopped ones are
  not**; the `tags` hostvar is deprecated and a 2.22 reserved name until `use_deprecated_tags: false`; a config file
  must be named `*.aws_ec2.yml`; without `regions` it scans every region (~30 s against moto). (L16, I07, I08)
* `cache_timeout: 0` = never expires for the file cache plugins. (I08)
* `keyed_groups` with `prefix: ""` still prepends the separator (`_web`). (L16)
* `ansible-test` downloads `get-pip` from ci-files.testing.ansible.com and ignores `PIP_*` variables, but pip reads
  `/etc/pip.conf`; pylint's `dill` pin is a GitHub archive (vendored as a wheel). (X05, infra)
* A module with `#!/usr/bin/env python3` doesn't run at all on 2.22 ("The module interpreter '/usr/bin/env python3'
  was not found"); `#!/usr/bin/python3` runs but bypasses interpreter discovery - sanity wants `#!/usr/bin/python`. (X05)
* `become` on Rocky: sudo's `secure_path` has no `/usr/local/bin` - call your own tools by absolute path. (E07)
* Earlier findings from the learn track (git roles need `meta/main.yml`, community.general 14's air-gapped
  dependency, empty `ANSIBLE_CALLBACKS_ENABLED` crashes 2.22, `UseDNS` per SSH session...) are in PLAN.md §12.

## Build your own scenario

```
scenarios/X09-short-symptom/
  scenario.yaml    id, title, kind: incident|learn, level 1-3, domain, nodes: [web1, web2], wave, est
  ticket.md        "# Title" / "**OPS-123** · P1 · Reporter: ..." / symptoms / constraints / **Test**: ...
  hints.md         ## Hint 1..3 (from "where to look" to "what to type")
  files/           the repo as found (copied into workspace/ before setup)
  .lab/setup.sh    build the past (ap site.yml, ws_commit "msg" "author"), then inject the fault
  .lab/verify.sh   check "desc" cmd... ; verdict      (runs in the CI checkout, bash -u, no pipefail)
  .lab/solve.sh    reference fix (selftest)            (runs in workspace/, set -euo pipefail)
  .lab/solution.md "# Solution - <root cause>", Root cause, (Diagnose), Fix, Interview notes
```
Scripts run in a fresh `bash` with `lib/common.sh` + `lib/ans.sh` loaded, the lab environment exported,
`$WS` (workspace), `$CI` (CI checkout, verify only), `$SCN` (the scenario dir), `$STATE_DIR`, `$CTL`, `$NET`.

| Setup / solve | Verify |
|---|---|
| `ap <playbook> [args]` (in the controller, logged) | `applies`, `converged` (check mode, 0 changes), `idempotent` |
| `ctl "<cmd>"` / `run_logged "$SETUP_LOG" ...` | `ap_json ...` then `stats_ok '<jq>'`, `task_result`, `task_skipped`, `task_not_skipped`, `out_has` |
| `ws_commit "msg" ["author"]` | `nx <node> "<cmd>"`, `svc_active`, `http_get <url>` (curl from the controller) |
| `nx <node> "<cmd>"` (root on a node), `node_rebuild <node>` | `ctl_ci "<cmd>"`, `lint_ok "<args>"` |
| `publish <repo> <tag\|-> <src> [msg]` (git registry) | `ws_has <regex>`, `vault_encrypted`, `untouched`, `not <cmd>` |
| `remember k v`, `lab_setenv NAME value` (CI env, `./lab sh`, verify) | `recall k`, `check_eventually <s> "desc" cmd` |

House rules (PLAN.md §11):
* Only the nodes in `nodes:` start, fresh per lab. nginx sites on 8080 or with their own `server_name`.
* Verify judges outcomes on the nodes **and** a check-mode convergence run; guard rails catch the cheap way out
  (`changed_when: false` on writes, skip lists, rolled-back rotations, `host_key_checking = False`).
* Probes that deploy use unique values (`$RANDOM`) and restore a good state - selftest runs verify on the broken
  state first.
* Don't pipe `docker exec` into `grep -q` with large outputs and rely on `pipefail` - verify runs without it.

Then: `./lab selftest X09` must print `broken:ok fixed:ok`, `python3 tools/catalog.py .` regenerates
`docs/CATALOG.md`; the README tables are edited by hand.

## What the lab deliberately does NOT do

* No real cloud, no internet after the build, no privileged containers, no Docker socket in lab containers.
* No AWX / Automation Controller (no verifiable AWX release since 24.6.1, needs Kubernetes) - its building
  blocks are here: execution environments, inventories, vault credentials, job-style CI scripts.
* No Windows, no network devices (`network_cli`) - a `connection: local` API track is still on the backlog.
* No real cloud: the AWS labs use moto (EC2 only); no EDA controller UI - the activation is the rulebook CLI.
* No mitogen (unsupported on 2.22).
