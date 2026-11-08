# ansible-lab

**Modern Ansible - ansible-core 2.22.0** on Debian 12 and Rocky 9 nodes, hands-on and offline: a guided
**learn track** (16 labs) and **47 break/fix incidents** taken from real postmortems: host keys after a rebuild,
`vars/` beating group_vars, the 2.19 templating overhaul, 2.22 secret masking, handlers lost after a failure,
`run_once` inside `serial`, lint 26 profiles, molecule, execution environments - and since wave 2 Event-Driven
Ansible (ansible-rulebook), the `amazon.aws.aws_ec2` inventory against a fake AWS, `strategy: free` races,
`throttle`, canary `order`/`max_fail_percentage` maths and `ansible-test sanity`. `./lab interview` puts you on the
clock with three random tickets.
Every node is a real systemd + sshd container, packages come from an air-gapped mirror, roles from a local git
"registry". You get a ticket, a git repo "as found", and `./lab verify` judges your fix the way CI would - on a
fresh checkout, with real Ansible runs and probes on the nodes.

```
host (unprivileged)          ./lab (bash) · workspace/ (git repo "as found" - you fix things here, IDE friendly)
│
docker network "ansiblelab" 10.78.0.0/24 - internal: no internet for anything on it
├── ans-repo   10.78.0.2   http://repo.acme.internal   apt + dnf mirror (the only package source)
├── ans-ctl    10.78.0.5   CONTROLLER  python 3.13 + ansible-core 2.22.0, ansible-lint 26.11, molecule 26.11,
│                          ansible-navigator 26.11, ansible-builder 3.2.0, ansible-rulebook 1.3.2 (+ Java 21),
│                          boto3, pinned collections (amazon.aws 12.1.0, ansible.eda 2.13.0, ...)
│                          /work = workspace/, /ci = CI checkout, https://git.acme.example -> local bare repos
├── ans-aws    10.78.0.6   http://aws.acme.internal:4566  fake AWS (moto 5.2.5, EC2) - only in the cloud labs
├── ans-eda    10.78.0.7   http://eda.acme.internal:5000  EDA activation (ansible-rulebook) - only in the EDA labs
├── ans-lb1  .10  ans-web1 .11  ans-web3 .13  ans-app1 .14  ans-test1 .31     Debian 12  ┐ systemd + sshd,
└── ans-web2 .12  ans-app2 .15  ans-db1  .21                                  Rocky 9    ┘ NOT privileged
                                             (fresh containers per lab - only the nodes a lab needs)
```

* Plan, research & design decisions: [PLAN.md](PLAN.md) · How faults are built (+ build your own): [docs/FAULTS.md](docs/FAULTS.md)
* All labs with root causes (**spoilers**): [docs/CATALOG.md](docs/CATALOG.md) · Interview prep: [docs/INTERVIEW-QUESTIONS.md](docs/INTERVIEW-QUESTIONS.md)
* Separate from `../linux-lab`, `../swarm-lab`, `../terra-labs` - own containers (`ans-*`), network, state.
  The host's own ansible (if any) is never used.

## Requirements

Linux, Docker (your user can run `docker`), `git`, `jq`, `python3` (+ PyYAML), `curl`, `ssh-keygen` (OpenSSH client).
~4 GB disk (images ~3.4 GB, mirror 160 MB, wheelhouses ~110 MB), ~2 GB RAM for the biggest labs.
Internet once for `./lab build` (~1 GB of base images and packages); offline afterwards.

## Quick start

```bash
./lab build          # once: controller + node images, package mirror, collections, wheels
./lab list
./lab start L01      # learn track: fresh nodes + workspace, task printed
./lab start T01      # an incident: broken on purpose, ticket printed
./lab sh             # shell in the controller at /work: ansible-playbook, ansible-lint, molecule, ...
./lab verify         # PASS / FAIL on a fresh CI checkout of workspace/
./lab hint           # 3 progressive hints;  ./lab solution  when stuck
./lab stop           # throw the nodes away
```
`./lab node web2` is a root console on a node, `./lab ssh web2` real SSH as the `ansible` user.
`./lab start random` picks an unknown incident. `./lab diff` shows your changes.
Edit files in `workspace/` with your IDE; run Ansible in `./lab sh` (or `./lab run ansible-playbook site.yml`).
EDA labs: `./lab eda logs` (the activation's log), `./lab eda restart` (re-read the repo),
`./lab eda post docs/alerts/<file>.json` (send an alert like the monitoring does).
Cloud labs: the fake AWS credentials and endpoint are in the controller's environment (`env | grep AWS` in `./lab sh`).

### Interview mode

```bash
./lab interview              # 3 random incidents, 45 min (15 per ticket); ./lab interview 2 30 = 2 tickets, 30 min
./lab interview status       # ticket k/n, time left, hints used
./lab verify                 # a PASS stops the clock for the ticket
./lab interview next         # move on (an unsolved ticket scores 0); after the last one: the score card
./lab interview stop         # end now
```
Points: 10 x level per ticket, each hint -20 %, `./lab solution`/`solve` -> 0, solved after the time is up -> half.
The lab IDs stay hidden until the score card; past cards are in `.state/interviews.log`.

## How to play

* The ticket's **Test** line is the definition of done. Constraints in the ticket ("keep `--tags deploy`",
  "no `skip_list`", "don't undo the rotation") are checked too.
* `workspace/` is a git repo with history - `git log -p` is often the first clue.
* `./lab verify` copies workspace/ to `/ci` (no `.ansible/` caches) and runs `ansible-playbook` there with the
  JSON callback: does it apply, does a check-mode run show **zero changes**, and do the nodes really behave
  (curl from the controller, `sshd -T`, files, services)? "It ran green" is not enough.
* The past was real: setup ran the team's playbooks against fresh nodes exactly as they did. Configs, lost
  handler notifications, duplicated lines and vault headers are genuine, not mocked text.

## Learn track

| ID | Lab | Lvl |
|---|---|---|
| L01 | Lab tour - inventory, ad-hoc, config | • |
| L02 | First playbook on two OS families | • |
| L03 | Variables and precedence | • |
| L04 | Templates, handlers and validate | •• |
| L05 | Loops, conditionals and blocks | •• |
| L06 | Roles with argument specs and OS-specific vars | •• |
| L07 | Collections and requirements - pinned and offline | •• |
| L08 | Vault and secret masking (2.22) | •• |
| L09 | Inventory at scale - constructed groups and patterns | •• |
| L10 | Rolling updates with drain, health gates and run_once | ••• |
| L11 | ansible-lint and molecule | •• |
| L12 | Execution Environments - build and run | •• |
| L13 | Upgrade a 2.16-era repo to ansible-core 2.22 | •• |
| L14 | Speed and observability | •• |
| L15 | Event-Driven Ansible - heal nginx from a monitoring webhook | •• |
| L16 | Cloud inventory - amazon.aws.aws_ec2 against a fake AWS | •• |

## Incidents

| ID | Ticket | Area | Lvl |
|---|---|---|---|
| D01 | Monitoring 2.0: nginx alerts reach EDA (HTTP 200) - nothing gets fixed | event-driven (EDA) | •• |
| D02 | Flapping check: EDA restarted nginx on web1 23 times in 10 minutes | event-driven (EDA) | •• |
| E01 | New CI idempotence gate fails: app1 reports changed=5 on every run | execution | • |
| E02 | Audit: sshd still allows 4 auth tries and X11 forwarding - the hardening run is green | execution | • |
| E03 | PR dry-run always says "Stop the app for the upgrade" - reviewers stopped reading it | execution | •• |
| E04 | Postmortem: release 2.0.0-rc1 took the whole site down for 4 minutes | execution | ••• |
| E05 | Restore test failed: last night's dump stops after a few rows | execution | •• |
| E06 | Release 3.2.0: the schema migration ran twice | execution | ••• |
| E07 | Deploy fails since `strategy: free` - "has no attribute 'shop_node_id'" | execution | •• |
| E08 | After the LB rebuild only one web node is in rotation - every deploy is green | execution | •• |
| E09 | Release 5.0.0 broke two nodes - the canary should have caught it | execution | •• |
| I01 | Redeploy fails: web2 "UNREACHABLE! Host key verification failed" | inventory / connection | • |
| I02 | CI deploy: "provided hosts list is empty" - since the runner change | inventory / connection | • |
| I03 | Web tier lost its settings after the inventory reorganisation | inventory / connection | • |
| I04 | New node app1 fails every task - "python3: not found" | inventory / connection | •• |
| I05 | Every play fails: "Missing sudo password" after the CIS hardening | inventory / connection | •• |
| I06 | app1: "Failed to set permissions on the temporary files Ansible needs to create when becoming an unprivileged user" | inventory / connection | •• |
| I07 | Every host UNREACHABLE since the switch to the EC2 inventory | inventory / connection | • |
| I08 | Scale-out web3 never got the release - the deploy fails on an instance terminated last week | inventory / connection | •• |
| P01 | New web node web2 (Rocky 9) fails in the website role | platforms | • |
| P02 | New node web2: "Failed to download metadata for repo 'baseos'" | platforms | •• |
| P03 | SSH banner missing on web2 - the deploy failed once, now it's green | platforms | • |
| R01 | Shop 2.4.1 deploy fails at the smoke check - re-running doesn't help | roles / collections | •• |
| R02 | Release 1.5.0 never reached app1 - the deploy job was green | roles / collections | •• |
| R03 | Banner deploy fails since this morning: "missing required arguments: banner_lines" | roles / collections | • |
| R04 | New logrotate task fails: "couldn't resolve module/action 'community.general.logrotate'" | roles / collections | •• |
| R05 | Idempotence check red: 00-base.conf changes on every run; shop accepts 40 MB uploads | roles / collections | •• |
| S01 | Deploy fails since the prod vault password rotation: "Decryption failed (no vault secrets were found that could decrypt)" | secrets | • |
| S02 | Security: new employees' initial passwords are readable in the deploy log | secrets | • |
| S03 | The vault password file has been in the repo since 2019 | secrets | •• |
| S04 | PR bot posted the DB password - old and new - in a comment | secrets | • |
| T01 | CI image upgraded to ansible-core 2.22 - every deploy fails | templating / upgrade | • |
| T02 | Security scan: prod web1 has no hardening marker - every deploy is green | templating / upgrade | • |
| T03 | Worker deploy fails after the controller upgrade: "Type 'range' is unsupported for variable storage" | templating / upgrade | •• |
| T04 | CI preview of the 2.24 defaults: "'ansible_os_family' is undefined" | templating / upgrade | •• |
| T05 | Smoke test fails with 401 since the runner moved to ansible-core 2.22 | templating / upgrade | •• |
| T06 | Shop deploy fails at "Validate nginx config" since the group_vars cleanup | templating / upgrade | •• |
| T07 | Login banner on every node shows raw template code | templating / upgrade | •• |
| V01 | Raised appserver workers to 8 in group_vars - still 2 everywhere | variables | • |
| V02 | Prod responses got 4x bigger after raising the upload limit | variables | • |
| V03 | Web-only deploys fail: "object of type 'dict' has no attribute 'all_ipv4_addresses'" | variables | •• |
| V04 | Shop unreachable on 8080 since the metrics role was added - it answers on 9100 | variables | •• |
| X01 | Lint gate red after the runner upgrade to ansible-lint 26 (production profile) | pipeline / testing / EE | • |
| X02 | Role CI red: "Idempotence test failed because of the following tasks: node_report : Node report" | pipeline / testing / EE | •• |
| X03 | CI: "You need to install jmespath prior to running json_query filter" - but the EE declares it | pipeline / testing / EE | •• |
| X04 | Deploy takes 20+ minutes on the 40-node fleet - and grows with every node | pipeline / testing / EE | •• |
| X05 | Collection CI red: `ansible-test sanity` fails on acme.ops.app_flag | pipeline / testing / EE | •• |

## Rules of the game

* Don't read `learn/*/.lab/` and `scenarios/*/.lab/` - that's the answer key.
* Fix it like you would in a team: in code, reviewable, so the **next** run (and the next new node) is right.
  `ignore_errors`, `changed_when: false` on writes, `ALLOW_BROKEN_CONDITIONALS`, `skip_list` and
  `host_key_checking = False` are not fixes - the verify scripts check for them.
* Hand-fixing a node is sometimes part of the recovery (a lost handler notification), never the whole fix.

## Safety

* Nothing runs privileged. Nodes get `SYS_ADMIN` (systemd in a container), a private cgroup namespace,
  384 MB RAM and 1 CPU each. No Docker socket inside any lab container.
* The lab network is `--internal`: nodes and controller can't reach the internet - or your LAN.
* SSH keys, known_hosts and git config live in `.state/`; your `~/.ssh`, `~/.ansible` and `~/.gitconfig` are
  never read or touched.
* Everything is named `ans-*` and labelled `ansiblelab.scenario`; `./lab stop` removes the nodes (and the
  per-lab `ans-aws` / `ans-eda`), `./lab down` the controller, mirror and network. Execution environment images
  are tagged `acme/ee:*`.
* The fake AWS is moto in memory: nothing ever talks to a real AWS account; its keys are dummies.

## Maintenance

```bash
./lab doctor                     # images, mirror, controller versions, disk
./lab status
./lab selftest all               # every lab: start -> verify (must FAIL) -> solve -> verify (must PASS), ~60 min
./lab selftest wave2             # only the wave-2 labs (L15, L16, D/E07-E09/I07-I08/X05), ~20 min
./lab down                       # remove controller, mirror and network too
python3 tools/catalog.py .       # regenerate docs/CATALOG.md after adding a lab
```
Upgrading tools: edit `versions.env`, `./lab build`, `./lab selftest all`. Several incidents (T02, T04, E03,
S02, S04) depend on exact ansible-core 2.22 behaviour - re-check them first after a core upgrade; L16/I07 depend on
amazon.aws 12 (the `tags` hostvar deprecation, terminated instances hidden by default), D02 on ansible-rulebook's
`throttle`, X05 on the exact `ansible-test sanity` findings of 2.22.

The controller that runs is `ansiblelab/ctl:2` = `ctl:1` (wave 1, unchanged) + a layer for EDA, AWS and offline
`ansible-test` (`infra/ctl2`). Its Python packages and moto's come from `cache/pypi/<set>` (a wheelhouse that
`./lab build` downloads once) - not from `cache/wheels`, which the EE labs copy into their build contexts.
