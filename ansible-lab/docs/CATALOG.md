# ansible-lab - catalog

> **Spoilers.** The *Root cause* and *Verified by* columns give the answers away. Play first: `./lab start <id>`.

Legend: level `•` easy (5-15 min) · `••` medium (15-25 min) · `•••` hard (25-40 min). *Nodes*: the managed
containers the lab starts (Debian 12: lb1 web1 web3 app1 test1 · Rocky 9: web2 app2 db1).
Every lab is checked by `./lab selftest <id>`: it must verify as FAIL when started and PASS after the reference fix.
This file is generated: `python3 tools/catalog.py .`

## L - Learn track (16)

| ID | Lab | Lvl | Nodes | Verified by |
|---|---|---|---|---|
| L01 | Lab tour: inventory, ad-hoc commands, ansible.cfg | • | web1, web2 | inventory: group web = web1 + web2, tier: frontend; ansible.cfg: inventory, remote_user ansible, forks 20; ansible all -m ping works without -i; user deploy exists on web1 and web2 (bash) |
| L02 | First playbook on two OS families | • | web1, web2 | web1 answers on 8080: Hello from web1 running Debian 12; web2 answers on 8080: Hello from web2 running Rocky 9; nginx is enabled on both; site.yml converges (check mode: no changes) |
| L03 | Variables and precedence | • | web1, web2 | web1: env prod, owner Platform, contact web-oncall; web2: env staging, owner Team Rocky, contact web-oncall; the role is unchanged (configured from the inventory); site.yml converges |
| L04 | Templates, handlers and validate | •• | lb1, web1, web2 | lb1 balances across web1 and web2; the config has one server line per web host; an invalid value is rejected by validate, live config untouched; site.yml converges |
| L05 | Loops, conditionals and blocks | •• | web1, web2 | alice (admin per OS) and bob exist, carol is gone; /etc/acme/agent-missing on both nodes (rescue ran); users.yml converges (check mode: no changes) |
| L06 | Roles with argument specs and OS-specific variables | •• | web1, web2 | web1 (Debian): /etc/default/acme; web2 (Rocky): /etc/sysconfig/acme; appconfig_mode: chaos fails argument validation; a call without appconfig_port fails validation ... |
| L07 | Collections and requirements: pinned, reproducible, offline | •• | web1, web2 | a fresh checkout installs everything from requirements.yml; community.general 14.0.0; ansible.posix 2.2.2; role acme.logrotate at v1.0.0 ... |
| L08 | Vault and secret masking (ansible-core 2.22) | •• | web1, web2 | group_vars/web/vault.yml is encrypted with vault ID prod; no plain DB password anywhere in the repo; a verbose CI run (-v --diff) works; ...and prints neither the password nor the token (plain or base64) ... |
| L09 | Inventory at scale: constructed groups and patterns | •• | web1, web2, app1, db1 | constructed groups with the right members; only prod web servers carry /etc/acme/patched; patch.yml converges; a host moved to prod in the CMDB is targeted automatically |
| L10 | Rolling updates: serial, drain, health gates, run_once | ••• | lb1, app1, app2, db1 | deploying a new version loses zero requests and updates both nodes; both app nodes are back in rotation; its migration is logged exactly once; a repeated deploy of that version changes nothing ... |
| L11 | ansible-lint and molecule | •• | test1 | ansible-lint (production profile) reports nothing; no skip/warn lists to hide findings; molecule test passes on a fresh checkout; mutant: a task that always changes -&gt; molecule fails (idempotence) ... |
| L12 | Execution Environments: build one, run your playbook in it | •• | web1 | image acme/ee:1 exists with ansible-core 2.22.0 and jmespath; /etc/acme/services.txt on web1 lists shop,api; site.yml converges when run inside the EE; the EE definition is version 3 and declares jmespath |
| L13 | Upgrade a 2.16-era playbook to ansible-core 2.22 | •• | web1, web2 | runs on 2.22 warning-free, with INJECT_FACTS_AS_VARS=False; web1 matches the spec (Debian 12); web2 matches the spec (Rocky 9); create_dirs: false skips the spool directories ... |
| L14 | Speed and observability | •• | web1, web2 | a cold run of site.yml takes under 12 s; UseDNS is off on both nodes; profile_tasks/timer callbacks enabled; pipelining on, SSH multiplexing not disabled ... |
| L15 | Event-Driven Ansible - heal nginx from a monitoring webhook | •• | web1, web3 | the activation starts from the CI checkout (rulebooks/nginx.yml); a 'nginx down' alert for web1 brings nginx back; web1 serves the shop page again; web3's nginx was not restarted ... |
| L16 | Cloud inventory - amazon.aws.aws_ec2 against a fake AWS | •• | web1, web2, web3, db1 | ansible-inventory (ansible.cfg) lists exactly shop-db-1 shop-web-1 shop-web-2; group web = shop-web-1 shop-web-2, group db = shop-db-1; ansible_host = the instances' private IPs; hosts carry EC2 hostvars (instance_id, ec2_tags) - the inventory comes from EC2 ... |

## I - Inventory & connection (8)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| I01 | Redeploy fails: web2 "UNREACHABLE! Host key verification failed" | • | web1, web2 | re-trust a rebuilt host the right way | site.yml runs cleanly and a second run changes nothing; web2 serves the site; the trusted key for web2 is web2's real host key; host key checking is not disabled anywhere; web1 was left alone (not rebuilt) |
| I02 | CI deploy: "provided hosts list is empty" - since the runner change | • | web1, web2 | world-writable directory, ansible.cfg ignored | ci/deploy.sh runs green on a fresh checkout; ...and deployed the job ID to both web nodes; the CI build directory is not world-writable |
| I03 | Web tier lost its settings after the inventory reorganisation | • | web1, web2 | group name and group_vars file must match (and be valid) | web1 and web2 serve on 8081 with X-Tier: frontend; no warning about invalid group names; site.yml converges |
| I04 | New node app1 fails every task - "python3: not found" | •• | web1, app1 | bootstrap Python with raw | app1 is configured by site.yml; a node stripped of Python is bootstrapped and configured by site.yml alone; site.yml converges |
| I05 | Every play fails: "Missing sudo password" after the CIS hardening | •• | web1, web2 | become password from Vault | site.yml converges non-interactively; the become password is in a vault file with ID prod; no plaintext password in the repo; sudo on the nodes still requires a password (no NOPASSWD) |
| I06 | app1: "Failed to set permissions on the temporary files Ansible needs to create when becoming an unprivileged user" | •• | app1 | install acl | /home/acme/app.ini exists, owned by acme, 0600; site.yml converges; no world-readable temp file fallback |
| I07 | Every host UNREACHABLE since the switch to the EC2 inventory | • | web1, web2, db1 | choose the inventory hostname (Name tag) and the connection address (private IP) explicitly | the inventory names hosts by their Name tag (shop-db-1 shop-web-1 shop-web-2); ansible_host = the instances' private IPs; the inventory still comes from EC2 (instance_id hostvars); site.yml applies on every host; host_vars/shop-db-1.yml applies: shop-db-1 is the primary; host key checking is still on; site.yml converges (check mode: no changes) |
| I08 | Scale-out web3 never got the release - the deploy fails on an instance terminated last week | •• | web1, web2, web3, app1 | a never-expiring inventory cache, and stopped instances in the inventory | ci/deploy.sh hits exactly the running web instances and succeeds; shop-web-3 (scaled out yesterday) serves release 2.3.0; after a scale-in (shop-web-2) and a scale-out (shop-web-4) the very next job hits exactly the new fleet; shop-web-4 got the release |

## V - Variables & precedence (4)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| V01 | Raised appserver workers to 8 in group_vars - still 2 everywhere | • | web1, web2 | tunables belong in defaults/, not vars/ | both nodes run with workers = 8; role knobs can be overridden from inventory (timeout); site.yml converges |
| V02 | Prod responses got 4x bigger after raising the upload limit | • | web1, web2 | merge dictionaries explicitly | prod: gzip on, keepalive 65, 50m uploads; staging: 10m uploads; a changed shared default still reaches prod; no global hash_behaviour = merge; site.yml converges |
| V03 | Web-only deploys fail: "object of type 'dict' has no attribute 'all_ipv4_addresses'" | •• | web1, db1 | gather facts for hosts outside --limit | site.yml --limit web runs on a fresh runner; web1's db.conf points at db1 (10.78.0.21); --limit web converges (check mode); nothing is changed on db1 |
| V04 | Shop unreachable on 8080 since the metrics role was added - it answers on 9100 | •• | web1 | role variables share one namespace: prefix them | web1 serves the shop on 8080; web1 serves metrics on 9100; ansible-lint var-naming passes for both roles; site.yml converges |

## T - Templating & upgrades (2.19-2.24) (7)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| T01 | CI image upgraded to ansible-core 2.22 - every deploy fails | • | web1, web2 | conditionals must be booleans (ansible-core &gt;= 2.19) | site.yml converges on ansible-core 2.22 (no errors, no changes); TLS task runs by default; enable_tls: false really skips the TLS task; an empty app_name is still rejected by the validation; ALLOW_BROKEN_CONDITIONALS is not used anywhere |
| T02 | Security scan: prod web1 has no hardening marker - every deploy is green | • | web1, web3 | embedded templates in conditionals | deploy runs with the 2.23 preview; prod web1 has the hardening marker; staging web3 has no prod marker; only enabled sysctl settings are written; no embedded-template / delimiter warnings (preview off); site.yml converges; ci/pipeline.sh still runs the 2.23 preview |
| T03 | Worker deploy fails after the controller upgrade: "Type 'range' is unsupported for variable storage" | •• | app1 | range() and omit with 2.19+ templating | site.yml deploys; 3 worker spool dirs exist; both config files exist; site.yml converges; workers_count is still the knob (workers_count: 4) |
| T04 | CI preview of the 2.24 defaults: "'ansible_os_family' is undefined" | •• | web1, web2 | facts via ansible_facts only | site.yml deploys with fact injection off; web1 record: web1, Debian 12, sudo; web2 record: web2, Rocky 9, wheel; records carry the real Python version and CPU count; no INJECT_FACTS_AS_VARS deprecation (old default); site.yml converges |
| T05 | Smoke test fails with 401 since the runner moved to ansible-core 2.22 | •• | web1 | masked secrets: hand over via a 0600 file, not stdout | ci/pipeline.sh passes the smoke test; the token is not in the CI output (plain or base64); files holding the token are 0600 and not committed; vault file still encrypted; deploy.yml converges on the web tier |
| T06 | Shop deploy fails at "Validate nginx config" since the group_vars cleanup | •• | web1 | render types, not their Python representation | site.yml deploys; shop.acme.test serves the shop; www.acme.test serves the shop; rendered vhost has no list syntax / empty directive; site.yml converges; a set shop_error_page still renders error_page |
| T07 | Login banner on every node shows raw template code | •• | web1, web2 | untrusted data is never templated (2.19+) | site.yml deploys; web1 motd: web1, Debian 12, production; web2 motd: web2, Rocky 9, production; no template code left in /etc/motd; site.yml converges |

## R - Roles & collections (5)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| R01 | Shop 2.4.1 deploy fails at the smoke check - re-running doesn't help | •• | web1 | handlers run at the end of the play, and die with a failed host | web1 serves 2.4.1; site.yml runs green; site.yml converges; a new release goes live in one run (smoke check passes); back on 2.4.1 |
| R02 | Release 1.5.0 never reached app1 - the deploy job was green | •• | app1 | tags on include_role don't reach the role's tasks | ci/release.sh puts a new version on app1; the release job doesn't run Base packages; ci/release.sh still uses --tags deploy; release 1.5.0 is on app1 (full run converges) |
| R03 | Banner deploy fails since this morning: "missing required arguments: banner_lines" | • | web1, web2 | pin roles to tags | acme.banner is pinned to a released tag; fresh role install works; site.yml converges with the pinned role; banners unchanged on web1 and web2 |
| R04 | New logrotate task fails: "couldn't resolve module/action 'community.general.logrotate'" | •• | web1 | a vendored collection shadows the installed one | site.yml deploys; logrotate policy for /var/log/acme (daily, 14); the repo resolves community.general 14.0.0; site.yml converges |
| R05 | Idempotence check red: 00-base.conf changes on every run; shop accepts 40 MB uploads | •• | web1 | role dependencies with different parameters run twice | a second run changes nothing; nginx_base runs once per host; shop rejects a 5 MB upload (413); api accepts a 5 MB upload (200); site.yml converges |

## E - Execution & idempotency (9)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| E01 | New CI idempotence gate fails: app1 reports changed=5 on every run | • | app1 | modules know state, commands don't | a second run changes nothing; drift (symlink, user) is repaired and reported as changed; release unpacked, config enabled; ansible-lint: no-changed-when, command-instead-of-*; site.yml converges |
| E02 | Audit: sshd still allows 4 auth tries and X11 forwarding - the hardening run is green | • | web1 | lineinfile regexp must match before *and* after | site.yml runs; sshd -T: permitrootlogin no, maxauthtries 3; sshd -T: clientaliveinterval 300, x11forwarding no; each managed setting is defined exactly once; a changed value takes effect in one run; site.yml converges |
| E03 | PR dry-run always says "Stop the app for the upgrade" - reviewers stopped reading it | •• | app1 | a skipped read makes the dry run lie | check mode passes with no changes (converged node); check mode predicts the restart for app_version=9.9.9; app1 untouched by dry runs (1.0.0, running); no ignore_errors in the repo; the real deploy works |
| E04 | Postmortem: release 2.0.0-rc1 took the whole site down for 4 minutes | ••• | lb1, web1, web2, web3 | serial, fail fast, drain, health-gate | the current state converges (site.yml, no changes); a broken release: zero failed requests, at most one node touched, the play stops; a healthy deploy updates every node again; all three web nodes are back in rotation on lb1 |
| E05 | Restore test failed: last night's dump stops after a few rows | •• | app1 | async without poll is fire-and-forget | backup.yml runs; the shipped dump is complete (trailer of this run); the shipped dump equals the one on app1; the dump still runs asynchronously |
| E06 | Release 3.2.0: the schema migration ran twice | ••• | app1, app2, db1 | run_once is per batch | a new release deploys; its migration ran exactly once; the migration ran before any app node got the release; both app nodes have the release; the app rollout is still serial |
| E07 | Deploy fails since `strategy: free` - "has no attribute 'shop_node_id'" | •• | web1, web2, web3 | a cross-host dependency inside a `strategy: free` play needs a barrier: split the play | deploy.yml applies on all nodes, in under $LIMIT s; every node's /etc/shop-cluster.conf lists web1, web2, web3 with their node IDs; deploy.yml converges (check mode: no changes) |
| E08 | After the LB rebuild only one web node is in rotation - every deploy is green | •• | lb1, web1, web2, web3 | delegated tasks run in parallel per host: `throttle: 1` on the registration | from an empty registry, one deploy registers web1 web2 web3; haproxy on lb1 has web1, web2 and web3 UP; lb-register (the network team's tool) is unchanged - in the repo and on lb1; the deploy is not serialized (no play-level serial/throttle, forks &gt; 1); a second deploy changes nothing (check mode) |
| E09 | Release 5.0.0 broke two nodes - the canary should have caught it | •• | web1, web2, app1, app2 | `order: sorted` replaced the canary; `max_fail_percentage: 50` tolerated one failure per batch | 4.2.0 reaches all four nodes; 5.0.0 (fails on Rocky): only the canary web2 got it, the run stopped; 4.2.0 reaches all four nodes again; 5.0.1 (fails on Debian): canary passed, the first failing batch stopped the run - web1 never got it; 4.2.0 reaches all four nodes again; deploy.yml converges (check mode, 4.2.0: no changes) |

## S - Secrets & vault (4)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| S01 | Deploy fails since the prod vault password rotation: "Decryption failed (no vault secrets were found that could decrypt)" | • | web1, web3 | give Ansible every vault secret it needs | site.yml deploys to prod and staging; web1 (prod) has the prod DB password; web3 (staging) has the staging DB password; prod vault opens with the new password; prod vault does NOT open with the old password; no password in the repo; site.yml converges |
| S02 | Security: new employees' initial passwords are readable in the deploy log | • | web1 | masking covers known secrets only: no_log for loops over secrets | ci/deploy.sh output holds no initial password; a JSON-callback run holds no initial password; alice and bob accept their initial passwords; site.yml converges |
| S03 | The vault password file has been in the repo since 2019 | •• | web1 | a leaked vault password means rekey everything | .vault_pass is not tracked and is git-ignored; every vaulted value opens with the new password, none with the old; no vault password in any file; site.yml converges; web1's credentials unchanged |
| S04 | PR bot posted the DB password - old and new - in a comment | • | app1 | diff: false for templates that hold secrets | real deploy writes the current password; PR check output (text) shows no password, still reports the change; PR check output (JSON) shows no password, DB client config changed; site.yml converges |

## P - Platforms & packages (3)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| P01 | New web node web2 (Rocky 9) fails in the website role | • | web1, web2 | generic modules, OS-specific names in vars | site.yml deploys to both nodes; web1 serves the home page (Debian, apache2); web2 serves the home page (RedHat, httpd); one role for both OS families; site.yml converges |
| P02 | New node web2: "Failed to download metadata for repo 'baseos'" | •• | web2 | repository configuration is part of the play | a freshly re-imaged node converges in one run; web2 serves the home page; every enabled repo on web2 is the internal mirror; site.yml converges |
| P03 | SSH banner missing on web2 - the deploy failed once, now it's green | • | web1, web2 | service names differ per OS (and a lost handler) | web1: sshd uses the banner; web2: sshd uses the banner; a banner config change is applied on both OS families in one run; site.yml converges |

## X - Pipeline, testing & execution environments (5)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| X01 | Lint gate red after the runner upgrade to ansible-lint 26 (production profile) | • | web1 | fix the findings, don't hide them | ci/lint.sh passes; .ansible-lint: profile production, nothing skipped; no # noqa, no .ansible-lint-ignore; site.yml converges; web1 runs nginx with port=8080 |
| X02 | Role CI red: "Idempotence test failed because of the following tasks: node_report : Node report" | •• | test1 | no timestamps in managed files | ci/molecule.sh passes; a tampered report is repaired and reported as changed; no changed_when / check_mode on the report task; mutant: a task that always changes -&gt; molecule fails |
| X03 | CI: "You need to install jmespath prior to running json_query filter" - but the EE declares it | •• | web1 | a changed EE definition needs a new image and a new tag | ci/ee-image names a new tag with ansible-core 2.22.0 + jmespath; site.yml converges inside that EE; acme/ee:1 is unchanged (immutable tag); web1 lists the public services: shop,api |
| X04 | Deploy takes 20+ minutes on the 40-node fleet - and grows with every node | •• | web1, web3, app1, app2 | remove the multipliers | a no-change run takes under 15 s; same result on the nodes; site.yml converges; host key checking still on |
| X05 | Collection CI red: `ansible-test sanity` fails on acme.ops.app_flag | •• | web1 | make code, documentation and packaging rules agree (no ignore file) | ci/sanity.sh passes (ansible-test sanity, all tests); no sanity ignore entries, no noqa / pylint: disable comments; ci/smoke.sh passes (set, idempotent, check mode, absent); without path: the flag lands in /etc/shop/flags.conf (the documented default); state=enabled is rejected (not in the documented choices) |

## D - Event-Driven Ansible (EDA) (2)

| ID | Ticket (symptom) | Lvl | Nodes | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| D01 | Monitoring 2.0: nginx alerts reach EDA (HTTP 200) - nothing gets fixed | •• | web1, web3 | the rule matched the v1 payload; v2 is nested and targets FQDNs | the activation starts from the CI checkout (rulebooks/web.yml); a v2 'critical' alert for web3.acme.internal brings nginx back on web3; web3 serves the shop page again; web1 was not touched; a v2 'ok' alert runs nothing (nginx on web1 stays stopped); site.yml converges (check mode: no changes) |
| D02 | Flapping check: EDA restarted nginx on web1 23 times in 10 minutes | •• | web1, web3 | throttle the rule per host (`once_within` + `group_by_attributes`) | the activation starts from the CI checkout (rulebooks/web.yml); web1 is healed; web3 is healed too (a different host inside the window); exactly one nginx start on web1 for 8 alerts; exactly one nginx start on web3 for 2 alerts; site.yml converges (check mode: no changes) |

## Totals

| Track | Labs |
|---|---|
| Learn | 16 |
| I - Inventory & connection | 8 |
| V - Variables & precedence | 4 |
| T - Templating & upgrades (2.19-2.24) | 7 |
| R - Roles & collections | 5 |
| E - Execution & idempotency | 9 |
| S - Secrets & vault | 4 |
| P - Platforms & packages | 3 |
| X - Pipeline, testing & execution environments | 5 |
| D - Event-Driven Ansible (EDA) | 2 |
| **All** | **63** |

Wave 2 (EDA, cloud inventory, execution control, ansible-test) is marked by `wave: 2` in scenario.yaml -
`./lab selftest wave2`. Practise under pressure: `./lab interview` (3 random incidents, timer, score).

## Backlog (see PLAN.md §4)

`delegate_facts`, `connection: local` / API-only automation, `ansible-test units` / `integration`, decision
environments (ansible-builder for ansible-rulebook), EDA with Kafka / Alertmanager sources.
