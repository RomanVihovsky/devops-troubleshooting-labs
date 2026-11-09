# ansible-lab - plan (approved 2026-11-07)

## Context

`ansible-lab/` held only `ansible-lab-data.pdf` (local input, not in the repo): a ChatGPT overview of beginner,
intermediate and advanced topics plus best practices. It contains no concrete labs and its
version advice is dated. You want **modern Ansible labs** in the house style of the sibling labs:
* `./lab` CLI
* a learn track plus break/fix incidents
* hidden `.lab/{setup,verify,solve}.sh`, with `selftest` proving each lab broken -> fixed
* offline after one build, nothing privileged

The newest sibling, `terra-labs`, already provides the framework to reuse:
* lib, workspace git history, CI-checkout verification, local git registry, catalog generator

`linux-lab` provides the unprivileged systemd node containers that run safely on this host.

---

## 0. Decisions (questionnaire, 2026-11-07)

| Question | Answer |
|---|---|
| Controller | **ansible-core 2.22.0** (released 2026-11-02) on Python 3.13. The community `ansible` 15 package is still beta, so we use **core + explicitly pinned collections** (best practice anyway) |
| Managed nodes | **Debian 12 + Rocky 9**: systemd + sshd containers, unprivileged, packages from a local apt/dnf mirror |
| Lab format | Learn track + break/fix incidents, same framework as terra-labs |
| Extras (left to us) | **Execution Environments in wave 1** (that is how Ansible runs in CI/AAP today). Event-Driven Ansible in wave 2. **AWX out**: no verifiable release since 24.6.1 (Jul 2024), and it needs Kubernetes |

Found on this host:
* ansible-core **2.17.14** on Python 3.10. Too old: core 2.22 needs Python >= 3.13, and ansible-lint 26.x
  excludes 2.17 (CVE-2026-11332). So the controller is a container; the host's ansible is never used.
* No `python3-venv`, no podman, Docker 29 with no compose plugin (use linux-lab's `docker:29-dind` compose fallback).
* `debian:12`, `python:3.12-slim` and `nginx:1.27-alpine` are local. `python:3.13-slim` and `rockylinux/rockylinux:9`
  are reachable (pulled once).
* 16 GB free disk, 19 GB RAM. The repo is now git-tracked; `ansible-lab/` is untracked.

## 1. Research summary + PDF triage

| PDF says | Status Nov 2026 | Lab does |
|---|---|---|
| `pip install ansible` | `ansible` 14.6 = core 2.21; 15.x (core 2.22) is beta | core 2.22.0 + `requirements.yml` collections pinned in `versions.env` |
| Molecule "6" with Docker driver | molecule **26.11**; drivers come from molecule-plugins 26.11 | molecule with the default (delegated) driver against a lab node, so no Docker socket in the controller |
| ansible-lint in CI | ansible-lint **26.11**, profiles (`production`), FQCN rules | L11 + incident X01 |
| `when:` truthiness, `{{ }}` anywhere | **2.19 templating overhaul**: non-boolean conditionals error; embedded templates in expressions error; native types only; untrusted templates don't render; `range` / `omit` / `None` changes | upgrade lab L13 + incidents T01-T07 |
| `ansible_distribution` etc. | `INJECT_FACTS_AS_VARS` deprecated (2.20); default flips to False in **2.24** | everything uses `ansible_facts[...]`; incident T04 |
| `no_log` placeholder `VALUE_SPECIFIED_IN_NO_LOG_PARAMETER` | **2.22 secret masking**: `$REDACTED$`, `debug` hides registered secrets, `invocation` no longer returned by default | L08 + incident T05 |
| `uri follow_redirects: yes` | `yes`/`no` removed in 2.22 | in the L13 legacy repo |
| `ansible-config dump` | defaults to `-t all` (2.22) | L01 |
| AWX/AAP for teams | AWX releases paused since 2024 | out of scope; navigator/EE is what AAP uses |
| Jenkins/GitLab/GHA YAML | still valid ideas | local `ci/pipeline.sh`, like terra-labs L14 |
| Nir Geier AnsibleLabs, Red Hat interactive labs | references only | nothing copied (licences); topics inform the learn track |

## 2. Environment design

```
host (unprivileged)          ./lab (bash) · workspace/ (git repo, you edit here - IDE friendly)
│
docker network "ansiblelab" 10.78.0.0/24   (linux-lab = .77, terra = .79, swarm = 172.30)
├── ans-repo  10.78.0.2   nginx:1.27-alpine -> http://repo.acme.internal  (apt + dnf mirror, built once)
├── ans-ctl   10.78.0.5   CONTROLLER  ansiblelab/ctl:1  python:3.13-slim + ansible-core 2.22.0,
│                         ansible-lint, molecule, ansible-navigator, ansible-builder, yamllint,
│                         pinned collections; /work = workspace (bind), /ci = CI checkout (bind),
│                         git.acme.example -> local bare repos (url.insteadOf, as in terra-labs)
├── ans-lb1   10.78.0.10  Debian 12  (haproxy)      ┐
├── ans-web1  10.78.0.11  Debian 12  (nginx)        │ ansiblelab/node:{debian12,rocky9}
├── ans-web2  10.78.0.12  Rocky 9    (nginx)        │ systemd PID 1 + sshd + python3 + sudo,
├── ans-db1   10.78.0.21  Rocky 9    (postgresql)   │ NOT privileged (linux-lab's x-host anchor)
└── ans-test1 10.78.0.31  Debian 12  (molecule target)┘ fresh containers per lab, only the nodes a lab needs
```

* **Safety**
  * linux-lab's proven settings: `cgroup: private`, tmpfs `/run`, cap_add only as needed, never privileged.
  * No Docker socket in the controller.
  * Everything is named `ans-*` and labelled `ansiblelab.scenario`.
* **Offline**
  * Controller and node images are built once.
  * The apt/dnf mirror holds just the packages the roles install (nginx, haproxy, postgresql, chrony,
    rsyslog, acl, nftables, python3-psycopg2, ...), so `update_cache: true` works without internet. That is also realistic: an
    air-gapped internal mirror.
  * Collections are installed from `cache/collections/*.tar.gz` and git; roles from the local git registry.
* **Verification as CI would do it**
  * `./lab verify` copies workspace/ to `/ci` (no caches).
  * It runs `ansible-playbook` in the controller with the `ansible.posix.json` callback: syntax, then a check-mode
    convergence run (`changed=0, failed=0, unreachable=0`).
  * It probes nodes directly (`docker exec`: systemctl, curl, file contents, users) and checks guard rails
    (vault files still encrypted, `ALLOW_BROKEN_CONDITIONALS` not set, no blanket `ignore_errors`, lint skip-list limits).
* **SSH**: a lab-generated key; `known_hosts` per lab is managed by `./lab` (realistic host-key incidents).
* **Budgets**:
  * disk ~2 GB (ctl ~600 MB, rocky node ~400 MB, debian node ~250 MB, mirror ~400 MB)
  * RAM ~3.5 GB peak (nodes 384 MB each, ctl 1 GB)
  * network ~1.5 GB once

### Scenario anatomy (identical to terra-labs)
```
scenarios/T01-broken-conditionals/
  scenario.yaml   id, title, kind: learn|incident, level 1-3, domain, nodes: [web1,web2,...], wave, est
  ticket.md       "# Title" / "**OPS-123** · P1 · Reporter: ..." / symptoms / constraints / **Test**: ...
  hints.md        ## Hint 1..3
  files/          the repo as found (inventory/, group_vars/, roles/, playbooks/, ansible.cfg, requirements.yml, ci/)
  .lab/setup.sh   apply "the past" (playbooks run in ans-ctl against fresh nodes), commit history, inject the fault
                  (in repo, on nodes, in the mirror or git registry)
  .lab/verify.sh  check / verdict on the CI checkout + node probes
  .lab/solve.sh   reference fix (selftest);  .lab/solution.md: Root cause / Diagnose / Fix / Interview notes
```

### CLI (`./lab`), mirroring terra-labs
`build`, `doctor`, `list [--learn|--incidents|--domain T]`, `start <id|random>`, `ticket`, `sh` (shell in ans-ctl at /work),
`ssh <node>`, `node <node>` (root shell on a node), `env`, `verify`, `hint`, `diff`, `solution`, `solve`, `reset`, `stop`,
`status`, `up/down`, `selftest <ids|all|learn|incidents|wave1>` (with `LAB_SELFTEST` = don't mark solved).

### Verify toolkit (`lib/ans.sh`, on top of terra-labs' `lib/common.sh`)
* **Running Ansible**
  * `ctl <cmd>`: run in the controller, in /ci or /work.
  * `ap_stats <playbook> [args]`: per-host stats from the JSON callback.
  * `converged <playbook>`: check mode, zero changes, failures and unreachables.
  * `idempotent <playbook>`: a real run, then a second run with zero changes.
  * `lint_ok [profile]`, `molecule_ok <role>`.
* **Probing nodes**
  * `node <n> <cmd>`, `svc_active <n> <unit>`, `http_ok <url> [text]` (curl from ans-ctl).
  * `file_has <n> <path> <regex>`, `pkg_installed <n> <pkg>`.
* **Workspace and history**
  * `vault_encrypted <file>`, `no_secret_in <dir|output> <string>`, `untouched <path>`, `same_ctr <n>` (node not rebuilt).
  * `remember/recall`, `ws_commit`, `publish` (role/collection versions into the git registry).

## 3. Learn track (wave 1: 14 labs, all auto-graded)

| ID | Lab | Modern skills |
|---|---|---|
| L01 | Lab tour | YAML inventory, ad-hoc, facts, `ansible.cfg` (+ the world-writable-dir rule), become, `ansible-config dump` (2.22: `-t all`) |
| L02 | First playbook on two OS families | `ansible.builtin.package`/`service`, idempotence, `--check --diff` |
| L03 | Variables & precedence | group_vars/host_vars, `ansible-inventory --graph --vars`, extra vars, role defaults vs vars |
| L04 | Templates & handlers | Jinja2 + `validate:`, notify/`listen`, `flush_handlers`, `ansible_facts[...]` only |
| L05 | Loops, conditionals, blocks | `loop`/`loop_control`, boolean `when` (2.19+), block/rescue/always, `changed_when`/`failed_when` |
| L06 | Roles with argument specs | `meta/argument_specs.yml`, defaults vs vars, OS vars via `first_found`, role-prefixed names |
| L07 | Collections & requirements | FQCN, pinned `requirements.yml` (tarballs + internal git), collections paths, roles from git |
| L08 | Vault & secrets (2.22 masking) | vault-ids, `encrypt_string`, `no_log`, `register_secret`/`mask_secrets`, vault password client script |
| L09 | Inventory at scale | `constructed` plugin (keyed_groups by os_family/env), patterns, `--limit`, inventory from a CMDB JSON |
| L10 | Rolling updates | `serial`, `max_fail_percentage`, haproxy drain via `delegate_to: lb1`, `uri` + `until`, `run_once` |
| L11 | Lint & molecule | ansible-lint `production` profile, molecule (delegated driver on ans-test1): converge/idempotence/verify |
| L12 | Execution environments | `execution-environment.yml` v3, ansible-builder, ansible-navigator `run --ee` (mechanism spike-gated, §5) |
| L13 | Upgrade a 2.16-era repo to 2.22 | broken conditionals, embedded templates, `range`/`omit`/`None`, injected facts, `bool`, `follow_redirects` |
| L14 | Speed & observability | `profile_tasks`/`timer`, pipelining, forks, fact caching (`jsonfile`), `strategy: free`, async; timed verify |

## 4. Incident catalog (symptom first; root cause = spoiler)

Wave 1 = **39 incidents** (★ = pilot). Level 1-3.

**I - Inventory & connection**

| ID | Ticket | Root cause / fix | Lvl |
|---|---|---|---|
| I01★ | `UNREACHABLE: Host key verification failed` on web2 since its rebuild | Host key changed. Re-trust properly (`ssh-keygen -R` + `ssh-keyscan` / known_hosts management); guard: host_key_checking stays on | 1 |
| I02 | CI ignores our inventory and remote_user | "Ansible is being run in a world writable directory, ignoring it as an ansible.cfg source"; fix permissions or `ANSIBLE_CONFIG` | 1 |
| I03 | group_vars for the web tier never apply | Group renamed `web-servers` vs `group_vars/web_servers.yml` + invalid-chars transform | 1 |
| I04 | New Rocky node fails: no python interpreter | Minimal image without python3; `raw` bootstrap or interpreter setting; discovery warnings | 2 |
| I05 | `Missing sudo password` after the security hardening | NOPASSWD removed; vaulted `ansible_become_password` per group | 2 |
| I06 | `Failed to set permissions on the temporary files` with `become_user: postgres` | Unprivileged become needs `acl` (from the mirror) or pipelining | 2 |

**V - Variables & precedence**

| ID | Ticket | Root cause / fix | Lvl |
|---|---|---|---|
| V01 | Our group_vars change has no effect | The role sets it in `vars/main.yml` (beats inventory); move it to defaults | 1 |
| V02 | Prod nginx lost gzip/keepalive after a "small" override | Dict override replaces, it doesn't merge; use `combine()` | 1 |
| V03 | Works without `--limit`, fails with `--limit web` | `hostvars['db1'].ansible_facts` is empty; gather or delegate facts / fact cache | 2 |
| V04 | web listens on 5432 | A role default (`port`) leaks across roles; role-prefixed variable names | 2 |

**T - Templating & upgrades (2.19-2.22)**

| ID | Ticket | Root cause / fix | Lvl |
|---|---|---|---|
| T01★ | After the upgrade: `Conditional result was 'yes' of type 'str'` | Booleans as strings in `when`; proper booleans or `bool`; guard: no `ALLOW_BROKEN_CONDITIONALS` | 1 |
| T02 | `Template delimiters are not supported in expressions` | `{{ }}` inside `when`/`assert` | 1 |
| T03 | `Type 'range' is unsupported` / task gets an empty option | `range()` needs `\| list`; `omit` in loop items -> `default(omit)` | 2 |
| T04 | Deprecation warnings flood CI, plus 2.24 readiness | `ansible_distribution` -> `ansible_facts['distribution']`; must converge with `INJECT_FACTS_AS_VARS=False` | 2 |
| T05 | 2.22: the deploy job no longer hands the API token to the smoke test | Secret masking (`$REDACTED$` in debug); hand over via a 0600 file, not stdout | 2 |
| T06 | nginx won't start: `server_name ['a', 'b'];` / `None` in config | Native types: `replace` on a list, `None` templates; `map`/`join`, explicit else | 2 |
| T07 | The MOTD shows raw `{{ ansible_hostname }}` | Untrusted template data (2.19 trust model): `template` lookup instead of `file` | 2 |

**R - Roles & collections**

| ID | Ticket | Root cause / fix | Lvl |
|---|---|---|---|
| R01 | New vhost deployed yesterday, nginx still serves the old config | The play failed after notify, so handlers never ran; restart + `force_handlers`/`flush_handlers` | 2 |
| R02 | `--tags deploy` runs nothing (or everything) | `include_role` vs `import_role` with tags/when (`apply:`) | 2 |
| R03 | Internal role changed under us | `requirements.yml` `version: main`; pin the tag that is deployed | 1 |
| R04 | Wrong collection version used despite requirements | Old vendored `./collections` first in `COLLECTIONS_PATHS`; remove/reorder | 2 |
| R05 | Role dependency runs twice and resets config | `meta` dependencies + `allow_duplicates`/params | 2 |

**E - Execution & idempotency**

| ID | Ticket | Root cause / fix | Lvl |
|---|---|---|---|
| E01 | CI idempotence check: always "changed" | `shell`/`command` without `changed_when`/`creates`; use modules | 1 |
| E02 | sshd_config grows by one line per run | `lineinfile` regexp never matches; fix + dedupe | 1 |
| E03 | `--check` run crashes, the real run works | Registered command skipped in check mode; `check_mode: false` for read-only tasks | 2 |
| E04★ | Rolling deploy took the whole site down | No `serial`/health gate/drain; verified by deploying a bad build while curling the LB | 3 |
| E05 | Backup "succeeded" but the archive is truncated | `async`/`poll: 0` never awaited (`async_status ... until finished`) | 2 |
| E06 | DB migration ran three times | `run_once` inside `serial` runs once per batch; separate play / `ansible_play_hosts_all[0]` | 3 |

**S - Secrets & vault**

| ID | Ticket | Root cause / fix | Lvl |
|---|---|---|---|
| S01 | `Decryption failed (no vault secrets were found that could decrypt)` | vault-id label mismatch after rekey (`prod@`); `vault_identity_list` | 1 |
| S02 | User passwords visible in CI logs | loop items printed: `no_log: true` (+ rotate) | 1 |
| S03 | Vault password file committed to git | Remove it, rekey, password client script from env; old password must fail | 2 |
| S04 | DB password shown in `--diff` output | `diff: false` on secret templates | 1 |

**P - Platforms & packages**

| ID | Ticket | Root cause / fix | Lvl |
|---|---|---|---|
| P01 | Role fails on Rocky: apt not found | `package` + OS vars (`first_found`), httpd/apache2-style name differences | 1 |
| P02 | New Rocky node: dnf can't reach repos (air-gapped) | Repo config must point to the internal mirror first (pre_tasks) | 2 |
| P03 | Handler fails on Rocky: service `ssh` not found | `ssh` vs `sshd`; OS-specific vars | 1 |

**X - Pipeline, testing, EE**

| ID | Ticket | Root cause / fix | Lvl |
|---|---|---|---|
| X01 | ansible-lint 26 upgrade turned CI red | FQCN, `name[casing]`, yaml truthy, risky-file-permissions; fix code, limited skip_list | 1 |
| X02 | Molecule idempotence fails | Template embeds `ansible_date_time`; idempotent design | 2 |
| X03 | Works on my laptop, fails in the EE: `No module named 'jmespath'` | Python dep missing in `execution-environment.yml`; rebuild EE | 2 |
| X04 | Deploy takes 20+ minutes | sshd `UseDNS` + no pipelining + facts every play; pipelining, gather_subset, fact cache; timed verify | 2 |

**Wave 2** (built 2026-11-07/08, see §13): EDA (L15, D01, D02), `amazon.aws.aws_ec2` against moto (L16, I07, I08),
`strategy: free` / `throttle` / `order` + `max_fail_percentage` (E07-E09), `ansible-test sanity` (X05), `./lab interview`.

**Backlog**: `delegate_facts`, "connection: local" / API-only traps, `ansible-test units`/`integration`, decision
environments, EDA with Kafka/Alertmanager sources.

## 5. Build plan (phases with gates)

| Phase | Deliverable | **Gate** |
|---|---|---|
| 0. Spike + skeleton | `versions.env`, `infra/{ctl,node/debian12,node/rocky9,repo}`, `infra/compose.yml`, `lib/{common,ans}.sh`, `./lab build/doctor/up/down` | On this host: (a) both node images boot systemd **unprivileged**, sshd up, in ≤15 s; (b) ans-ctl pings both OS families; nginx/postgresql install from the **offline mirror** on each (`update_cache: true`) with the network blocked; (c) ansible-lint 26.11 + molecule 26.11 + navigator work with core 2.22.0 (else pin the tools and record it); (d) `ansible.posix.json` callback stats parse; (e) EE mechanism: ansible-builder build via host Docker + run the EE on `ansiblelab` (navigator in a container vs a direct `docker run`); pick the one that needs no socket inside ans-ctl; (f) RAM/disk budgets met. Results -> PLAN.md "Phase 0 result" |
| 1. Framework + 3 pilots | full `./lab`, verify toolkit, workspace git, selftest; pilots I01, T01, E04 | `./lab selftest I01 T01 E04` all `broken:ok fixed:ok`, start ≤ 45 s |
| 2. Learn track | L01-L14 | `selftest learn` green |
| 3. Wave 1 incidents | remaining 36, domain by domain | `selftest wave1` green; second run of every solved lab converged; `./lab stop` leaves no `ans-*` node containers |
| 4. Docs | README, docs/CATALOG.md (generated - reuse `terra-labs/tools/catalog.py`), docs/FAULTS.md, docs/INTERVIEW-QUESTIONS.md | links valid, catalog = labs |
| 5. Wave 2 | §13: 2 learn labs, 8 incidents, `./lab interview` | each new lab `broken:ok fixed:ok`; `selftest all` green on the new controller |

## 6. Risks & mitigations

| Risk | Mitigation |
|---|---|
| core 2.22 is 5 days old: lint/molecule/collections may lag | Phase 0 gate (c); pin tool versions that work; record exceptions in PLAN.md |
| Rocky 9 systemd unprivileged on this host | Phase 0 gate (a); fallback: AlmaLinux 9 or a Debian-only first wave |
| Docker Hub flaky (python:3.13-slim, rockylinux:9) | pull once; quay.io mirror for Rocky; images cached locally |
| Host freezes with privileged containers (linux-lab history) | never privileged; caps per node; per-node mem/cpu limits |
| Mirror coverage gaps (a role needs a package not mirrored) | package list in `versions.env`; `./lab build` fails loudly; a selftest catches it |
| Check mode limitations make "converged" lie | convergence = check run + node probes + (where needed) a real idempotence run |
| EE needs a container engine | no socket in ans-ctl; build/run from host-side lab helpers (spike decides) |

## 7. Files to create (all under `ansible-lab/`)
```
lab  versions.env  PLAN.md  README.md  .gitignore (root .gitignore: + /ansible-lab/workspace/)
lib/common.sh   <- terra-labs/lib/common.sh (check, check_eventually, verdict, remember/recall, md)
lib/ans.sh      controller/node helpers + verify toolkit; workspace + git-registry parts from terra-labs/lib/tf.sh
                (ws_reset, ws_commit, untouched, publish, run_lab_script, ci_checkout)
lib/compose.sh  <- linux-lab/lib/common.sh compose() with the docker:29-dind fallback
infra/node/debian12, infra/node/rocky9   <- linux-lab/infra/server (systemd hygiene, ssh-hostkeys.service, lab-init)
infra/ctl/Dockerfile   python:3.13-slim + pinned pip packages + collections from cache/
infra/repo/            mirror build scripts (apt: dpkg-scanpackages; dnf: createrepo_c) + nginx config
infra/compose.yml      x-node anchor (from linux-lab/infra/hosts.yml) + ans-ctl/ans-repo/nodes
learn/L01-... L14      scenarios/I01-... X04      tools/catalog.py (<- terra-labs/tools/catalog.py)
docs/{CATALOG,FAULTS,INTERVIEW-QUESTIONS}.md
```

## 8. Verification (end to end)
1. `./lab doctor`: images present, mirror reachable, ans-ctl versions match `versions.env`, disk/RAM ok.
2. `./lab selftest all`: every lab start -> verify FAIL -> solve -> verify PASS (results table with durations).
3. Offline proof: `HTTPS_PROXY/HTTP_PROXY` pointed at a dead port for the selftest run; nodes have no default route
   except the lab network; the mirror is the only package source.
4. Convergence: after each solve the playbook re-run in check mode shows `changed=0`.
5. Leak check: after `./lab stop` no `ans-*` node containers or volumes (infra containers stay until `./lab down`).
6. `shellcheck` on `lab`, `lib/*.sh`, all `.lab/*.sh`.
7. Manual play-through of the 3 pilots.

---

## 9. Phase 0 result (2026-11-07)

| Gate | Result |
|---|---|
| (a) systemd nodes, unprivileged | **PASS** - Debian 12 and Rocky 9 boot to `running` in ~2 s, sshd up, ~15 MB RAM idle each (linux-lab's settings: `--cgroupns=private`, tmpfs /run, `SYS_ADMIN`, seccomp/apparmor unconfined, never `--privileged`). Network `ansiblelab` is `--internal`: **no internet from nodes or controller** |
| (b) offline packages | **PASS** - mirror (apt flat repo + `createrepo_c`) is 157 MB; nginx/haproxy/postgresql install offline on both OS families |
| (c) tools on core 2.22.0 | **PASS** - ansible-lint 26.11 (`using ansible-core:2.22.0`), molecule 26.11, navigator 26.11, builder 3.2.0; collections posix 2.2.2, general 14.0.0, crypto 3.5.1, postgresql 5.1.1 |
| (d) JSON callback | **PASS** - `ansible.posix.json` stats + per-task host results parse with jq |
| (e) Execution Environments | **PASS** - `ansible-builder create` in ans-ctl -> `docker build --network none` on the host from `ansiblelab/ee-base:1` + offline wheelhouse (needs `bindep pyyaml packaging dumb-init==1.2.5`) -> `docker run --user <uid>:0 --network ansiblelab` (EE convention: arbitrary UID, group 0, HOME=/runner). No socket in the controller. `./lab ee build/run` wrap it |
| (f) budgets | **PASS** - images ~2.4 GB (ctl 535 MB, nodes ~450 MB each, ee-base ~430 MB), mirror 157 MB, RAM < 1.5 GB for 4 nodes |

Surprises:
* Host `python3-venv` is missing -> navigator can't run on the host; EE run via `docker run` (what navigator does).
* Debian's image ships `/usr/sbin/policy-rc.d` (services don't start on install) - removed in the node image.
* apt lists are empty in a fresh image -> `first_boot` runs `apt-get update` / `dnf makecache` (like cloud-init).
* ansible-galaxy refuses two versions of one collection in one download call -> one spec per call.
* 2.22 deprecates `ansible -o` and the `oneline`/`tree` callbacks (removal 2.23) - molecule triggers the warnings.
* 2.22 error texts carry the value's **origin**: `Conditional result (True) was derived from value of type 'str'
  at '/work/group_vars/all.yml:1:11'` (data tagging).

## 10. Phase 1 result (2026-11-07)

`./lab` (build, doctor, list, start, ticket, sh, run, ssh, node, ee, verify, hint, diff, solution, solve, reset,
stop, status, up/down, selftest) + `lib/{common,ans}.sh`. Pilots: **I01 40 s, T01 45 s, E04 89 s - all
`broken:ok fixed:ok`.** E04's broken run: 12 failed requests through lb1 and 3 nodes on the bad build; fixed: 0 and 1.

## 11. House rules for scenario authors

* `scenario.yaml` lists `nodes:`; Debian: lb1 web1 web3 app1 test1 · Rocky: web2 app2 db1. Fresh per lab.
* Repo layout per scenario: `ansible.cfg` (inventory, `remote_user = ansible`, `host_key_checking = True`,
  `interpreter_python = auto_silent`, pipelining), `inventory/hosts.yml`, `group_vars/`, `site.yml`, `roles/`.
* nginx: own `server {}` on **8080** with `root /usr/share/nginx/html` (exists on both distros) - avoids the
  distro default sites. haproxy needs `rise` time after restarts: setup waits (`retry ... http_get`).
* Setup builds the past with `ap ...` (logged), `ws_commit "msg" "author"`; older-core behaviour can be
  simulated with `ANSIBLE_ALLOW_BROKEN_CONDITIONALS=True`. `node_rebuild <n>` = golden-image rebuild (not re-trusted).
* Verify judges `/ci` with `converged` (check mode, 0 changes), `applies`, `idempotent`, `task_skipped`,
  `out_has`, node probes (`nx`, `svc_active`, `http_get` from the controller), guard rails (`ws_has`,
  `vault_encrypted`, `no_broken_cond_escape`, `untouched`). JSON task names of roles are `role : task`.
* Verify probes that change nodes (E04) must restore a good state before they finish.
* Verify runs with `bash -u` only (no `pipefail`, no `-e`); end pipelines from `docker exec` with
  `grep ... >/dev/null` rather than relying on pipefail. Future defaults are previewed with `lab_setenv`.

## 12. Build log

| Phase | Status |
|---|---|
| 2. Learn track | **L01-L14 done**, each `broken:ok fixed:ok` (2026-11-07) |
| 3. Wave 1 incidents | **39 done** (I6 V4 T7 R5 E6 S4 P3 X4), each `broken:ok fixed:ok` (2026-11-07) |
| 4. Docs | README, docs/CATALOG.md (generated by `tools/catalog.py`), docs/FAULTS.md, docs/INTERVIEW-QUESTIONS.md (44 questions; 52 since wave 2) |
| Full run | `selftest all`, offline (HTTP(S)_PROXY -> dead port): see "Full selftest" below |
| 5. Wave 2 | **L15, L16 + 8 incidents** (D01 D02 E07 E08 E09 I07 I08 X05), each `broken:ok fixed:ok`; `./lab interview` tested end to end; controller now `ansiblelab/ctl:2` (2026-11-08) - see "Wave 2 result" below |

Deviations from §4 (found while building - the real 2.22 behaviour made better incidents):
* **V04**: role *defaults* don't leak between roles (each task sees its own role's defaults first) - the leak
  needs the other role's `vars/`. Ticket: shop moves to the metrics port 9100.
* **E03**: on 2.22 a command skipped in check mode registers `rc: 0` / empty stdout - no crash. The incident is
  now "the dry run always predicts a restart" (reviewers stopped reading it).
* **X03**: "jmespath missing in the EE" is L12's lesson; the incident is now a **stale image tag** - the
  definition declares jmespath, CI still runs `acme/ee:1` (immutable tags, new tag + bump).
* **S02/S04** use secrets from a JSON export: 2.22 masks vault values and password lookups automatically, so
  the leaks are the ones masking can't see.
* **T02** is silent (2.23 preview skips the task without a warning), not an error.
* **R04** teaches the implicit playbook-adjacent `collections/` path as well.

Findings while building the incidents:
* `--internal` network -> no default route -> `ansible_facts['default_ipv4']` is `{}` (V03 uses `all_ipv4_addresses`).
* Masking replaces substrings: a vault password `pass` turns `password` into `$REDACTED$word`.
* `ANSIBLE_CONFIG=/dev/null` is rejected by 2.22; `ansible.cfg` has no inline comments; `-e k=4` is a string.
* `port` is a reserved variable name (lint `var-naming[no-reserved]`); molecule 26 needs `galaxy_info.namespace`.
* `encrypt_string` with vault password sources from cfg **and** CLI: "vault-ids default,default" (S03 order).
* `community.general.to_toml` needs `tomlkit` (not in the controller) -> R04 uses `community.general.logrotate` (12.5.0+).
* **Framework**: verify scripts no longer run with `pipefail` - `docker exec ... | grep -q` failed randomly
  (grep exits early, docker exec gets EPIPE). Each check is decided by its last command anyway.

Findings while building the learn track (all became lab content or framework fixes):
* haproxy 2.6 accepts `maxconn lots` -> L04 validates an unknown `balance` algorithm instead.
* Roles installed from git need `meta/main.yml` (galaxy_info) or ansible-galaxy refuses them.
* `community.general` 14 depends on `community.library_inventory_filtering_v1` - air-gapped installs must ship
  it too (L07 teaches it; the tarball is in `cache/collections`).
* With `vault_identity_list` set, `--vault-id prod@...` on top is ambiguous ("prod,prod") -> `--encrypt-vault-id`.
* ansible-lint `var-naming[no-role-prefix]` also applies to `register:` names in molecule playbooks.
* The node image disables SSH password auth globally, so a test that only checks that line proves nothing
  (L11 mutates `PermitRootLogin` instead).
* `UseDNS yes` + a dead resolver costs seconds per SSH **session** (file transfers open extra channels), so
  Ansible tuning alone is not enough (L14 fixes sshd via Ansible).
* An empty `ANSIBLE_CALLBACKS_ENABLED` crashes ansible-core 2.22 ("A non-empty plugin name is required");
  `ap_json` cuts the JSON document out of stdout instead.
* Verify probes that deploy (L10, E04) use unique versions / restore state - selftest runs verify on the broken
  state first.

### Full selftest (2026-11-07)

`HTTPS_PROXY=HTTP_PROXY=http://127.0.0.1:9 ./lab selftest all` -> **53/53 `broken:ok fixed:ok`** (14 learn + 39
incidents), ~40 min. Median lab 35 s; slowest L14 (368 s - its broken state waits on the dead resolver), X04 109 s,
X03 106 s (EE build). After `./lab stop`: no node containers (label `ansiblelab.scenario`); only `ans-ctl` and
`ans-repo` remain until `./lab down`. Every solved lab's verify includes a check-mode convergence run (gate:
"second run converged"). shellcheck: `lab`, `lib/*.sh` clean; `.lab/*.sh` clean at `-S warning`.

---

### Wave 2 result (2026-11-08)

Per-lab `./lab selftest` (offline network, ctl:2): L15 94 s, L16 80 s, D01 104 s, D02 125 s, I08 108 s, E08 142 s,
E09 260 s - all `broken:ok fixed:ok`; E07 and I07 also passed (their timings were lost when the host rebooted and
cleared `/tmp`). X05: `broken:ok`; its first fixed run exposed a bug in the lab's own `ci/smoke.sh` (below); after the
fix, solve + verify PASS. E08's lock change and X05's fix were re-checked by the full run below.

Full selftest on ctl:2 (2026-11-08): `HTTPS_PROXY=HTTP_PROXY=http://127.0.0.1:9 ./lab selftest all` ->
**63/63 `broken:ok fixed:ok`** (16 learn + 47 incidents: the 53 wave-1 labs on the new controller plus the 10 wave-2
labs), 68 min, no lab containers left behind (label `ansiblelab.scenario`).

Findings while building wave 2 (now lab content or framework fixes):
* `#!/usr/bin/env python3` in a module does not run on 2.22 ("The module interpreter '/usr/bin/env python3' was not
  found") - X05 plants `#!/usr/bin/python3` instead (runs, but fails the sanity shebang test).
* `ANSIBLE_COLLECTIONS_PATH=<tmp>` alone hides the system collections (`ansible.posix.json` callback "could not be
  loaded") - X05's `ci/smoke.sh` appends `/usr/share/ansible/collections`.
* Rocky's sudo `secure_path` has no `/usr/local/bin` - E07's tools are called by absolute path.
* E07 timing: slow steps of 10 s per node -> split play ~16 s, linear ~25 s; the verify limit is 21 s.
* amazon.aws 12 adds the deprecated `tags` hostvar (and a 2.22 reserved-name warning) until
  `use_deprecated_tags: false` - part of L16's task, set in I07/I08's configs.
* `git rm` of the last file deletes the directory (I07 setup); moto 500s when relaunching on a terminated instance's
  IP (scenarios stop/start instead).
* E08's race is deterministic (5/5 runs from an empty registry: green, one backend left); concurrent haproxy
  reloads could fail once, so the tool now locks its *apply* step only - the read stays outside ("a lock in the
  wrong place").
* `./lab interview stop` aborted silently under `set -e` when no hint was taken (`x=$(cat missing)`); fixed and
  tested with fabricated state (points maths: solved / late / hints / not seen).

Pre-commit pass: secrets scan clean (no keys/tokens/personal data); the moto dummy key no longer has the AWS key-ID
shape (`AKIA...` would trip secret scanning); the downloaded `get-pip` bootstrap (executed by ansible-test) is pinned
by sha256 in `versions.env` and checked by `./lab build`; `ansible-lab-data.pdf` (planning input) stays out of git
(`ansible-lab/.gitignore`); shellcheck clean; no published ports, no privileged containers, no Docker socket.

## 13. Wave 2 plan (2026-11-07)

Backlog from §4 -> **2 learn labs + 8 incidents + `./lab interview`**. A new domain **D - Event-Driven Ansible**
("decisions": rulebooks run in a *decision environment* in AAP). A learn lab for module development was left out
on purpose: X05 covers `ansible-test sanity` end to end, `units`/`integration` would need another wheelhouse.

### Infra (spiked 2026-11-07, all offline after `./lab build`)

| Piece | Decision | Spike result |
|---|---|---|
| Controller | **`ansiblelab/ctl:2` = `ctl:1` + a layer** (`infra/ctl2`): wave 1 keeps its exact Python env | +454 MB (JRE 21 ~200 MB, botocore ~100 MB) |
| EDA | ansible-rulebook **1.3.2** (drools_jpy 0.4.1, jpy 2.2.0 has cp313 wheels) + `openjdk-21-jre-headless` (Debian 13 has no 17) + **ansible.eda 2.13.0** | webhook source listens 4 s after start; `run_playbook` gets `ansible_eda.event`, runs on the **ruleset's `hosts:`** (`limit=all`) |
| EDA "activation" | `ans-eda` (10.78.0.7, `eda.acme.internal:5000`), image ctl:2, runs `infra/eda/activation.sh`: project dir (`/work` or `/ci`) + rulebook from `.state/eda/activation.env`, restarts the rulebook when it dies; `./lab eda logs/restart/post` | verify points the activation at `/ci`, fires alerts, restores `/work` |
| Cloud | **`ansiblelab/moto:1`** (moto[server] 5.2.5, own image like terra-labs') as `ans-aws` (10.78.0.6, `aws.acme.internal:4566`) + boto3 1.43.126 + **amazon.aws 12.1.0** in ctl:2 | `aws_ec2` works through `AWS_ENDPOINT_URL` (no endpoint in the inventory file - looks like prod). `RunInstances` honours `PrivateIpAddress`: **EC2 instances map onto the real lab nodes** by IP; every instance also gets a public IP + `ec2-54-...compute.amazonaws.com` name |
| ansible-test | `ansible-test sanity` (24 tests) offline: pip config `/etc/pip.conf` -> `/opt/pypi/sanity` (no index), pip 25.2 bootstrap script pre-seeded in `~/.ansible/test/cache`, `dill` (pylint's GitHub-archive pin) vendored as a wheel built from the same commit | first run ~50 s (one venv per test, cached in the controller afterwards) |
| Wheelhouse | `cache/pypi/{eda,aws,moto,sanity}` (`pip download` by `./lab build`; **not** `cache/wheels`: L12/X03 copy `/opt/wheels` wholesale into EE build contexts); images install **from these wheels** in a builder stage (legacy builder, no BuildKit: no `RUN --mount`) | 31 + 17 + 50 + 7 MB |

Findings during the spike (lab content): amazon.aws 12 deprecates the `tags` hostvar (`ec2_tags`, removal after
2026-12-01) and 2.22 warns "Found variable using reserved name 'tags'"; the default `hostnames` order picks the
public DNS name; `ansible-test` downloads `get-pip` from ci-files.testing.ansible.com and ignores `PIP_*` env.

### Labs

| ID | Ticket / task | Root cause -> fix (spoiler) | Verified by | Lvl |
|---|---|---|---|---|
| L15 | Event-Driven Ansible: a webhook rulebook that heals nginx (`web1 web3`) | write the rulebook (webhook source, condition on `event.payload`, `run_playbook`), remediation only on the event's host | activation loads the CI checkout's rulebook; a "nginx down" alert for web1 brings nginx back ≤ 60 s; web3 untouched; `status: up` and other checks trigger nothing; site.yml converges | •• |
| L16 | Cloud inventory: `amazon.aws.aws_ec2` against a fake AWS (`web1 web2 web3 db1`) | `*.aws_ec2.yml` name, `regions`, `filters` (Env=prod, running), `keyed_groups` on `ec2_tags.Role` without the leading `_`, `ec2_tags` not `tags` | inventory = running prod instances only, groups `web`/`db`, `ansible_host` = private IP, no deprecation; an instance launched during verify shows up; the static inventory is gone; site.yml converges | •• |
| D01 | "Monitoring 2.0: nginx alerts reach EDA (HTTP 200) - nothing gets fixed" | the v2 payload is nested (`alert.check`, `alert.state`, `alert.target.fqdn`): the condition never matches; then the FQDN matches no inventory host ("no hosts matched", green) | a v2 alert for `web3.acme.internal` heals web3 ≤ 60 s, web1 untouched; a v2 `ok` does nothing; converges | •• |
| D02 | "Flapping check: EDA restarted nginx on web1 23 times in 10 minutes" | no rule throttling: `throttle: once_within` + `group_by_attributes: [event.payload.host]` | a burst of 8 alerts for web1 + 2 for web3: both healed, **exactly one** restart each (journal); converges | •• |
| I07 | "Every host UNREACHABLE since the switch to the EC2 inventory" | default `hostnames` = public DNS (unresolvable in the VPC): `hostnames: [tag:Name]` + `compose: ansible_host: private_ip_address` | hostnames are the Name tags (host_vars apply), `ansible_host` private IPs, host key checking on, site.yml converges | • |
| I08 | "Scale-out: web3 never got the app - and the deploy fails on web9, terminated last week" | inventory cache with `cache_timeout: 0` (= never expires) + no `instance-state-name` filter | `ci/deploy.sh` hits exactly the running web fleet; verify then terminates web2 and launches web4 - the very next job sees it | •• |
| E07 | "Deploy fails since `strategy: free`: no attribute 'shop_node_id'" | a cross-host template in a free play reads facts other hosts haven't set yet: split the play (free per-host part, linear cluster part) | deploy applies; every `cluster.conf` lists all 3 node IDs; the deploy stays under 14 s (warm-ups overlap); converges | •• |
| E08 | "After every deploy lb1 balances to one web node only" | a non-concurrency-safe registration script delegated to lb1 runs 3x in parallel (last writer wins): `throttle: 1` | from an empty LB, one deploy registers all 3 nodes (haproxy UP); script untouched; no `serial`/`forks = 1` | •• |
| E09 | "Release 5.0.0 broke two nodes - the canary should have caught it" | `order: sorted` puts app1 first instead of the canary web2; `max_fail_percentage: 50` on a batch of 2 tolerates one failure ("must be exceeded") | bad build A (breaks Rocky) touches only web2 and stops; bad build B (breaks Debian) stops after the first failing batch; a good build reaches all 4; converges | •• |
| X05 | "Collection CI red: `ansible-test sanity` fails on acme.ops.app_flag" | validate-modules (doc vs argspec), import (`requests` at top level), shebang, pep8 | `ci/sanity.sh` passes; no ignore entries, no `noqa`/`pylint: disable`; the module still works (set, check mode, idempotent) on web1 | •• |

### `./lab interview`
`./lab interview [n=3] [minutes]` starts n random incidents one after another with the ID hidden (like
`start random`). Points per ticket = 10 x level; each hint -20 %; `solution`/`solve` -> 0; solved after the time
budget (default 15 min per ticket) -> half. `interview status|next|stop`; the score card names the labs and is
appended to `.state/interviews.log`. A manual `./lab start` abandons the interview.

### Gate
Each new lab `./lab selftest <id>` -> `broken:ok fixed:ok` offline (HTTP(S)_PROXY -> dead port); `selftest wave2`
covers learn + incidents with `wave: 2`; `tools/catalog.py` + README + this log updated.
