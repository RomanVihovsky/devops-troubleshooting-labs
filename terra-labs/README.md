# terra-labs

**Modern Terraform 1.17.1 + Terragrunt 1.2.1**, hands-on and offline: a guided **learn track** (14 labs)
and **37 break/fix incidents** taken from real postmortems - stale locks, state rollbacks, refactors that
want to destroy prod, mocks leaking into apply, lock files from a Mac, Terragrunt 1.x migrations...
No cloud account: AWS is a local [moto](https://github.com/getmoto/moto) server, containers run on your Docker,
modules come from a local git "registry". You get a ticket, a git repo "as found", and `./lab verify`
judges your fix the way CI would - on a fresh checkout.

```
host (unprivileged)
│  ./lab                         bash CLI · cache/bin: terraform, terragrunt, tflint (pinned, sha256-checked)
│  workspace/                    the repo "as found" - a git repo, you fix things here
│
├── tfl-moto      127.0.0.1:4566 fake AWS account (S3, IAM, EC2/VPC, SSM, SNS, KMS, Secrets Manager, ...)
├── tfl-*         containers / networks / volumes Terraform creates (label terralab.scenario)
└── .state/git    https://git.acme.example/platform/*.git  ->  local bare repos (module versions)
```

* Plan, research & design decisions: [PLAN.md](PLAN.md) · How faults are built (+ build your own): [docs/FAULTS.md](docs/FAULTS.md)
* All labs with root causes (**spoilers**): [docs/CATALOG.md](docs/CATALOG.md) · Interview prep: [docs/INTERVIEW-QUESTIONS.md](docs/INTERVIEW-QUESTIONS.md)
* Separate from `../linux-lab`, `../swarm-lab`, `../kubernetes-lab` - own containers (`tfl-*`), ports, state.

## Requirements

Linux, Docker (your user can run `docker`), `git`, `curl`, `unzip`, `jq`, `python3`, AWS CLI v2.
~2.5 GB disk. Internet once for `./lab build` (~0.5 GB); offline afterwards.

## Quick start

```bash
./lab build          # once: pinned binaries, moto image, provider mirror (~2 min)
./lab list
./lab start L01      # learn track: fresh workspace, task printed
./lab start S01      # an incident: broken on purpose, ticket printed
./lab sh             # shell in workspace/: terraform, terragrunt, aws -> fake AWS
./lab verify         # PASS / FAIL on a fresh CI checkout of workspace/
./lab hint           # 3 progressive hints;  ./lab solution  when stuck
./lab stop           # throw it all away
```
Prefer your own shell or IDE? `eval "$(./lab env)"` sets everything up (and `cd`s into workspace/).
`./lab start random` picks an unknown incident - interview practice. `./lab diff` shows your changes.

## How to play

* The ticket's **Test** line is the definition of done. Constraints in the ticket ("nothing may be
  recreated", "don't change the tests") are checked too.
* `workspace/` is a git repo with history - `git log -p` is often the first clue.
* `./lab verify` copies workspace/ to a fresh "CI checkout" (no `.terraform/`, no caches) and runs
  `init`/`plan` there. "Works on my machine" doesn't count - like in real life.
* The past was real: setup ran Terraform against the fake AWS exactly as the team did. State, locks,
  object versions and drift are genuine, not mocked text.

## Learn track

| ID | Lab | Lvl |
|---|---|---|
| L01 | First apply, fully offline | • |
| L02 | Variables done right | • |
| L03 | A container fleet with for_each | • |
| L04 | Remote state on S3 with native locking | • |
| L05 | Modules and versions | •• |
| L06 | Import, generate config, removed | •• |
| L07 | Lifecycle rules and conditions | •• |
| L08 | Secrets that never touch state | •• |
| L09 | terraform test: unit tests, mocks and integration | •• |
| L10 | Your first Terragrunt unit | • |
| L11 | Dependencies, mocks and the DAG | •• |
| L12 | Terragrunt Stacks | •• |
| L13 | DRY multi-env with feature flags | •• |
| L14 | A pipeline that deserves trust | ••• |

## Incidents

| ID | Ticket | Area | Lvl |
|---|---|---|---|
| C01 | DR region bootstrap fails: "Invalid for_each argument" | language | •• |
| C02 | "Error: Cycle" after adding one security group rule | language | •• |
| C03 | Staging apply created prod-* resources (and staging's are gone) | language | • |
| C04 | Deploy fails: 'The container name "/tfl-api" is already in use' | language | •• |
| C05 | Fresh environments fail randomly: "network tfl-jobs-net not found" | language | • |
| D01 | Refactor PR wants to recreate all 6 web containers | drift / refactor | •• |
| D02 | Plan after "move uploads into modules/bucket" destroys the uploads bucket | drift / refactor | • |
| D03 | The nightly apply reverted ops' 3 a.m. hotfix - and will tonight again | drift / refactor | •• |
| D04 | Apply fails: BucketAlreadyOwnedByYou (acme-analytics-exports) | drift / refactor | • |
| D05 | PR "hand the ML datasets bucket to the data team" would delete it | drift / refactor | • |
| D06 | Every apply "changes" the db security group - reporting loses DB access every other run | drift / refactor | •• |
| G01 | Every Terragrunt pipeline is red since the runner image upgrade | terragrunt | • |
| G02 | Standing up staging: init fails with "NoSuchBucket" | terragrunt | • |
| G03 | After "rename root terragrunt.hcl to root.hcl", nothing plans any more | terragrunt | • |
| G04 | Uploads fail in prod: NoSuchBucket "mock-uploads-bucket" | terragrunt | •• |
| G05 | Security scan: staging app runs inside the PROD VPC | terragrunt | • |
| G06 | env.hcl says 3 replicas, staging runs with 1 | terragrunt | • |
| G07 | New unit fails to init: "Unreadable module directory" | terragrunt | •• |
| G08 | Notifier settings are in us-east-1 - everything else is in Frankfurt | terragrunt | •• |
| G09 | Security change broke the prod pipeline: "dependency cycle" | terragrunt | •• |
| G10 | Last night's scale-up hotfix (4 replicas) vanished overnight | terragrunt | •• |
| M01 | CI plan shows changes nobody made - locally the plan is clean | modules | • |
| M02 | Upgrading tf-module-pgbox to v2.0.0 destroys the database volume | modules | ••• |
| M03 | Payments' pipeline broke after our network release: "Unsupported attribute" | modules | •• |
| P01 | CI: "doesn't match any of the checksums previously recorded in the dependency lock file" | providers | • |
| P02 | Renovate PR breaks init: "no available releases match the given constraints" | providers | •• |
| P03 | DR audit: the "Ireland" replica bucket is in Frankfurt | providers | •• |
| P04 | "Unsupported Terraform Core version" after vendoring the tags module | providers | • |
| S01 | Every terraform run fails: "Error acquiring the state lock" | state | • |
| S02 | After the "backend tidy-up", plan wants to create everything | state | • |
| S03 | Plan wants to create things that exist - after someone "fixed" the state | state | •• |
| S04 | Two pipelines keep deleting each other's resources | state | ••• |
| S05 | CI: terraform init fails with "Missing required argument" | state | • |
| X01 | Security finding: DB master password readable in Terraform state | pipeline / security | •• |
| X02 | Postmortem action: the pipeline applied a change nobody reviewed | pipeline / security | •• |
| X03 | Drift detector green for 6 weeks - prod limit was changed by hand | pipeline / security | • |
| X04 | main is red: terraform test fails after "simplify pricing" | pipeline / security | •• |

## Rules of the game

* Don't read `learn/*/.lab/` and `scenarios/*/.lab/` - that's the answer key.
* Fix it like you would in a team: in code, reviewable. `-lock=false`, deleting state, `-target` and
  `ignore_changes = all` are not fixes.

## Safety

* Nothing runs privileged. moto listens on 127.0.0.1 only.
* The real cloud is unreachable by construction: dummy keys, every AWS endpoint -> `http://localhost:4566`,
  AWS profiles unset, AWS config files isolated in `.state/aws/`. Your `~/.aws`, `~/.terraformrc` and
  `~/.gitconfig` are never read or touched.
* Everything the labs create in Docker is named `tfl-*` and labelled `terralab.scenario`; `./lab stop` removes it.

## Maintenance

```bash
./lab doctor                     # versions, docker, moto, disk
./lab status
./lab selftest all               # every lab: start -> verify (must FAIL) -> solve -> verify (must PASS), ~45 min
./lab down                       # remove the moto container too
```
Upgrading tools: edit `versions.env`, `./lab build`, `./lab selftest all`. The moto image includes a
small fidelity patch (`infra/moto/terralab_moto.py`) - see docs/FAULTS.md.
