# terra-labs - plan (approved 2026-11-06, wave 1 built)

A local playground for **modern Terraform 1.17 + Terragrunt 1.2**: a guided learn track and a
catalog of break/fix incidents. Same workflow as `../linux-lab`, `../swarm-lab` and `../kubernetes-lab`:

```
./lab start S01        # fresh workspace (a git repo) + fake AWS account, broken on purpose, ticket printed
./lab sh               # shell in workspace/: terraform, terragrunt, aws (-> moto) wired up
./lab verify           # PASS / FAIL, judged on a fresh "CI checkout" of workspace/
./lab hint | diff | solution | solve
```

Research input: two ChatGPT research reports on free Terraform/Terragrunt labs (not kept in the repo), triaged in §1.

---

## 0. Decisions (questionnaire, 2026-11-06)

| Question | Answer |
|---|---|
| Engine | **Terragrunt + Terraform** (`TG_TF_PATH=terraform`; Terragrunt 1.x defaults to `tofu`). OpenTofu is out of scope |
| AWS emulation | **moto server + no-cloud core.** Most labs use offline providers (`random`, `local`, `null`, `time`, `tls`, `terraform_data`, `kreuzwerker/docker`). AWS-shaped labs use moto (MIT, no account) |
| Lab format | **Learn track + break/fix incidents**, one framework. `./lab verify` grades both |
| Language / style | English, terse, house style of the sibling labs (ASCII diagrams, tables, `·` separators) |

Found on this machine:
* Terraform **1.17.1** and Terragrunt **1.2.1** are already installed (current releases)
* aws-cli 2.39, docker 29 (no compose plugin), kubectl
* `python:3.12-slim`, `nginx:1.27-alpine`, `redis:7-alpine` and `postgres:16-alpine` images are already local
* 8 vCPU, 19 GiB RAM, **17 GB free disk**
* No passwordless sudo, and Docker Hub was flaky earlier

## 1. Research summary + PDF triage

| PDF says | Status in Nov 2026 (verified) | What the lab does |
|---|---|---|
| `docker run localstack/localstack` (free) | Since **2026-03-23** it needs `LOCALSTACK_AUTH_TOKEN` and an account; the community image is sunset | **moto server**, built locally from `python:3.12-slim` with a pinned `moto[server]` |
| MinIO for S3 | No community images or binaries since Oct 2025; maintenance mode | moto S3 |
| DynamoDB table for state locking | Deprecated; S3 **native `use_lockfile`** (TF 1.10+) | `use_lockfile`; DynamoDB appears only in migration scenario S06 |
| Backend `endpoint =`, `s3_force_path_style`, `skip_metadata_api_check` | Renamed to `endpoints { s3 = }`, `use_path_style`, and `AWS_ENDPOINT_URL*` env vars | Modern names; endpoints come from env in `./lab sh` |
| `terragrunt run-all`, `apply-all`, `--terragrunt-non-interactive`, `--terragrunt-include-dir`, `graph-dependencies` | **Removed in TG 1.0** (checked on 1.2.1: `run-all` gives an unknown-command error). Replaced by `run --all`, `--non-interactive`, `--filter`, `dag graph`, `TG_*` env vars | Modern CLI everywhere; G01 is the migration incident |
| Root `terragrunt.hcl` + `find_in_parent_folders()` | `root.hcl` is the convention | `root.hcl`; G03 |
| Terragrunt silently creates the S3 bucket | 1.x requires `backend bootstrap` / `--backend-bootstrap` | G02 |
| TF 1.6.0, TG 1.2.0, `setup-terraform@v2`, `checkout@v3` | TF 1.17.1, TG 1.2.1 | `versions.env` |
| `terraform init -get-plugins=false` | Removed in TF 0.15 | Provider **filesystem mirror** in `cache/providers` |
| Katacoda; compose `version: '3'` | Katacoda shut down in 2022; the compose `version` key is obsolete | - |
| Issue categories: locks, backend mismatch, creds, mocks, dependency paths, version pins, module downloads | Still valid | Each becomes an incident (S01, S02, P01, P02, G04, G05...) |
| "Machine-readable lab spec" YAML | Good idea | `scenario.yaml` + `verify.sh` checks |
| Free labs: Nirgeier TerraformLabs, DSOXLab, KodeKloud TG playground, abohmeed/terragrunt-labs (MIT), okamos playground (GPL), HashiCorp tutorials | References only | **Nothing copied** (licensing); topics inform the learn track |

Modern features the labs teach:
* **TF 1.10-1.17:**
  * ephemeral resources and write-only attributes (`value_wo`)
  * `import` blocks with `for_each`, and import inside modules (1.16)
  * `removed` blocks and `lifecycle { destroy = false }`
  * `terraform test` with `mock_provider`, and functions in mocks (1.15)
  * variable/output `deprecated` (1.15)
  * `terraform query` + list resources (1.14)
  * `graph -format=mermaid` (1.16), `-minimal-refresh` (1.17)
* **TG 1.x:**
  * `run --all|--graph`, `--filter`/`--filter-affected`, `find`/`list`, `dag graph`
  * `backend bootstrap`, `hcl fmt|validate`, `render`, `--inputs-debug`, Run Report (`--report-file`), `--provider-cache`
  * stacks (`terragrunt.stack.hcl`, `unit`/`stack`/`values`, `expansion` for_each, `autoinclude` from 1.2)
  * `feature` flags, `exclude`, `errors { retry/ignore }`

## 2. Environment design

```
host (unprivileged, your user)
│  ./lab  (bash)        cache/bin/{terraform 1.17.1, terragrunt 1.2.1, tflint}  <- sha256-verified
│  ./lab sh  -> subshell in workspace/ with PATH, AWS_* dummies, AWS_ENDPOINT_URL,
│               TF_CLI_CONFIG_FILE=.state/terraformrc (fs mirror + plugin cache), TG_TF_PATH=terraform
│
├── docker: tfl-moto   terralab/moto:1   127.0.0.1:4566 -> 5000   (in-memory "AWS account", unprivileged)
├── docker: tfl-pg     postgres:16-alpine (only for pg-backend scenarios, optional)
├── docker network tfl-net 10.79.0.0/24  <- containers created BY Terraform (kreuzwerker/docker),
│                                           label terralab.scenario=<id>, mem-limited, never privileged
└── .state/git/*.git   local bare repos = "module registry" (tags v1.0.0, v1.1.0, v2.0.0...)
                       consumed as git::file:///...//modules/x?ref=v1.1.0  (offline, realistic)
```

* **Safety.** Nothing is privileged. kind on the host stays rejected, as in kubernetes-lab §2.1.
  * moto listens on 127.0.0.1 only.
  * `./lab stop` removes every container labelled `terralab.*`.
* **Offline after `./lab build`.**
  * Pinned providers are mirrored with `terraform providers mirror` into `cache/providers`.
  * The generated `terraformrc` uses `provider_installation { filesystem_mirror {...} }` plus a `plugin_cache_dir`, so the ~700 MB AWS provider is unpacked once.
  * The user's `~/.terraformrc` is never touched.
* **Reset is fast.**
  * Restarting `tfl-moto` gives an empty AWS account in ~2 s.
  * Scenario containers are removed by label, and `workspace/` is rebuilt.
* **workspace/ is a git repo.** Its first commit is "as found", so `./lab diff` shows your changes. Verify guard rails use it too, e.g. "the tests were not edited".
* **Budgets:** disk ~3 GB (providers ~2 GB, moto image ~0.4 GB, binaries ~0.3 GB); RAM <1 GB; network ~0.8 GB once.

### Scenario anatomy (newest sibling style: k8s `scenario.yaml` + linux 3-hint/Test style)
```
scenarios/G04-mock-vpc-in-prod/
  scenario.yaml   id, title, kind: learn|incident, level 1-3, domain, needs: [moto,docker,git,pg], est: 10-20m
  ticket.md       "# Title" / "**INFRA-214** · P1 · Reporter: platform on-call" / symptoms / constraints / **Test**:
  hints.md        ## Hint 1..3
  files/          the repo as found -> copied to workspace/ (git init, commit "as found")
  .lab/setup.sh   good apply -> then inject the fault (edit code, push old state, hand-made drift via aws cli,
                  stale .tflock, retag module repo...). Records facts with remember (bucket ctime, container IDs, lineage)
  .lab/verify.sh  check / check_eventually / verdict - checks outcomes, never file text alone
  .lab/solve.sh   reference fix (selftest)
  .lab/solution.md  Root cause / Diagnose / Fix / Interview notes
```
Learn labs (`learn/L01-...`) use the same anatomy. Their `ticket.md` is a task with steps and a **Test** line.

### Verify toolkit (`lib/tf.sh`, on top of a copied `lib/common.sh`)

| Helper | What it checks |
|---|---|
| `plan_clean <dir>` | `plan -detailed-exitcode` exits 0 (converged, no drift) |
| `tg_plan_clean <dir>` | `run --all plan -detailed-exitcode` exits 0, plus the Run Report JSON |
| `in_state <addr>` / `not_in_state <addr>` | `terraform state list` |
| `state_lineage_kept` | Lineage equals the one remembered at setup, so state was not recreated |
| `aws_ <args>` | aws-cli pointed at moto |
| `same_resource <kind> <id>` | Container ID, bucket creation date or sentinel object unchanged, so nothing was destroyed and recreated |
| `no_secret_in_state <string>` | Searches the state object pulled from moto S3 |
| `untouched <path>` | `git diff --quiet` against "as found" |
| `no_shortcuts` | Greps for `-lock=false`, a blanket `ignore_changes = all`, `nonsensitive(` |

### CLI (`./lab`)
* Same core verbs as linux and swarm: `build`, `list`, `start <id|random>`, `ticket`, `sh`, `verify`, `hint [n]`, `solution [-y]`, `solve`, `stop`, `status`, `selftest <id|all|wave1>`.
* New verbs:
  * `doctor`: versions, docker access, moto health, disk
  * `up` / `down`: moto, pg
  * `aws ...`: pre-pointed at moto
  * `diff`
  * `reset`: re-run setup for the current scenario
  * `list --learn | --incidents | --domain G`

## 3. Learn track (guided, ~15-30 min each, all auto-graded)

| ID | Lab | Modern skills |
|---|---|---|
| L01 | First apply, fully offline | init/plan/apply/destroy, lock file, `plan -out`, `-detailed-exitcode` |
| L02 | Variables done right | types, `optional()` defaults, cross-variable validation, sensitive, tfvars precedence, `console` |
| L03 | A container fleet with for_each | docker provider, maps of objects, `for`, dynamic blocks, removing one key safely |
| L04 | Remote state on S3 (moto) | bucket with versioning, `use_lockfile`, `init -migrate-state`, partial `-backend-config` |
| L05 | Modules and versions | extract a module, publish it to the local git registry with tags, `?ref=`, `moved` on extraction |
| L06 | Import, moved, removed | `import` + `for_each`, `-generate-config-out`, `removed { lifecycle { destroy = false } }`, import inside modules (1.16) |
| L07 | Lifecycle and conditions | create_before_destroy, prevent_destroy, ignore_changes, replace_triggered_by, pre/postconditions, `check` |
| L08 | Secrets that never touch state | ephemeral `random_password`, `aws_ssm_parameter.value_wo` + `value_wo_version` |
| L09 | `terraform test` | run blocks, `mock_provider`, `override_resource`, `expect_failures` |
| L10 | First Terragrunt unit | `root.hcl`, include, remote_state + generate, generate provider, `backend bootstrap`, `hcl fmt`, `render` |
| L11 | Dependencies and the DAG | dependency + `mock_outputs` (allowed commands), `run --all`, `dag graph`, `find`/`list`, `--filter`, Run Report |
| L12 | Terragrunt Stacks | `terragrunt.stack.hcl`, unit/stack/values, `stack generate/run/output/clean`, `expansion` for_each, `autoinclude` |
| L13 | DRY multi-env | env/region hierarchy, `read_terragrunt_config`, `feature` flags, `exclude`, `errors { retry }` |
| L14 | A local pipeline | fmt -check, validate, tflint, test, `plan -out`, `show -json` + jq policy, apply the saved plan, drift check, `--filter-affected` |
| L15 | What's new 1.14-1.17 *(bonus, depends on the Phase 0 spike)* | `terraform query` / list resources, `deprecated` outputs, `graph -format=mermaid`, `-minimal-refresh` |

## 4. Incident catalog (symptom first; root cause = spoiler)

Wave 1 = **37 incidents** (★ marks the 3 pilots). Wave 2 = 12 more. Level 1-3.

**S - State & backends**

| ID | Ticket (symptom) | Root cause / fix | Lvl | W |
|---|---|---|---|---|
| S01★ | "Error acquiring the state lock" on every run since the nightly job | Stale `.tflock` from a killed job. Prove nothing is running, then `force-unlock <ID>`. Guard: no `-lock=false` | 1 | 1 |
| S02 | After a "backend tidy-up", plan wants to create 14 things that exist | Backend `key` changed, so state is empty. Revert, or `init -migrate-state` | 1 | 1 |
| S03 | Someone ran `state push -force`; plan now recreates half the stack | Recover the previous object version from the versioned state bucket | 2 | 1 |
| S04 | Two pipelines keep deleting each other's resources | Copy-pasted backend: two roots share one key. Split it (new key + `removed`/`import`) | 3 | 1 |
| S05 | CI `init` fails with "Missing required argument" / waits for input | Partial backend config file renamed; `-backend-config` path wrong | 1 | 1 |
| S06 | init warns that `dynamodb_table` is deprecated; migrate with no lock gap | Transition config `use_lockfile` + DynamoDB, then drop DynamoDB | 2 | 2 |
| S07 | Staging apply tried to modify prod objects | Workspace-insensitive names, `terraform.workspace` misuse | 2 | 2 |

**D - Drift, import & refactoring**

| ID | Ticket | Root cause / fix | Lvl | W |
|---|---|---|---|---|
| D01 | Converting count to for_each wants to recreate all 6 web containers | `moved` per index -> key. Guard: container IDs unchanged | 2 | 1 |
| D02 | A refactor into a module wants to destroy the uploads bucket (with data) | `moved` into `module.x`. Guard: sentinel object kept | 1 | 1 |
| D03 | Apply reverted ops' 3 a.m. hotfix | Drift: codify the hotfix in code. Plan clean, live value kept | 1 | 1 |
| D04 | Apply fails "BucketAlreadyOwnedByYou" | Bucket made by hand during an incident. `import` block; objects preserved | 1 | 1 |
| D05 | The PR handing a bucket to the data team would delete it | `removed { lifecycle { destroy = false } }` | 1 | 1 |
| D06 | Security group rules flip every apply | Inline rules and `aws_security_group_rule` fight; pick one model | 2 | 1 |
| D07 | One resource is replaced on every apply | `timestamp()` in triggers / `replace_triggered_by` | 1 | 2 |

**C - Language & config**

| ID | Ticket | Root cause / fix | Lvl | W |
|---|---|---|---|---|
| C01 | A new env fails "Invalid for_each argument... known only after apply" | for_each keyed by computed values; use static keys | 2 | 1 |
| C02 | "Error: Cycle" after adding a rule | Mutual SG references; separate rule resources | 2 | 1 |
| C03 | Staging apply created `prod-*` resources | A stray `*.auto.tfvars` beats terraform.tfvars (precedence) | 1 | 1 |
| C04 | Replacing the app fails "container name already in use" | create_before_destroy with a fixed name; add a suffix | 2 | 1 |
| C05 | A fresh env sometimes fails "network not found" | Name given as a string instead of a reference, so no implicit dependency | 1 | 1 |
| C06 | Callers broke after a module added a field | Object type without `optional()` | 1 | 2 |
| C07 | DB password showed up in CI logs | `nonsensitive()` used to silence an error | 1 | 2 |

**P - Providers & init**

| ID | Ticket | Root cause / fix | Lvl | W |
|---|---|---|---|---|
| P01 | CI: "checksums ... do not match the dependency lock file" | Lock file only has darwin hashes. `providers lock -platform=... -fs-mirror` | 1 | 1 |
| P02 | init: "no available releases match the given constraints" | Module `~> 5.0` vs root `>= 6.0`. Bump to the module tag built for v6 | 2 | 1 |
| P03 | The DR replica bucket is in the wrong region | Provider alias not passed (`providers = {}`, `configuration_aliases`); AWS v6 per-resource `region` | 2 | 1 |
| P04 | "Unsupported Terraform Core version" | Old module pins `~> 1.9.0`; fix the constraint properly | 1 | 1 |
| P05 | Works on a laptop, fails in CI: shared config profile "dev" | Hard-coded `profile` in the provider | 1 | 2 |
| P06 | "Module not installed" after bumping a ref | `init -upgrade` and what `.terraform/modules` caches | 1 | 2 |

**M - Modules**

| ID | Ticket | Root cause / fix | Lvl | W |
|---|---|---|---|---|
| M01 | Plan shows changes though nobody touched our repo | `?ref=main` floats; pin the tag that matches what is deployed | 1 | 1 |
| M02 | Module v2.0.0 upgrade wants to destroy the DB volume | Rename inside the module: add `moved` in the module repo, tag v2.0.1, bump the caller | 3 | 1 |
| M03 | Team B's pipeline broke after our release ("Unsupported attribute") | Renamed output read via `terraform_remote_state`; restore the alias with `deprecated` (1.15) | 2 | 1 |

**G - Terragrunt 1.x**

| ID | Ticket | Root cause / fix | Lvl | W |
|---|---|---|---|---|
| G01 | CI broke after upgrading Terragrunt | `run-all`, `--terragrunt-*`, `TERRAGRUNT_*` -> `run --all`, `--non-interactive`, `TG_*` | 1 | 1 |
| G02 | New env: init fails with NoSuchBucket | 1.x no longer auto-creates the backend; `backend bootstrap` | 1 | 1 |
| G03 | "Could not find ... in any parent folder" | Root renamed to `root.hcl`; `find_in_parent_folders("root.hcl")` | 1 | 1 |
| G04★ | Prod has resources named `mock-vpc-…` | `mock_outputs` without `mock_outputs_allowed_terraform_commands`; clean up the junk | 2 | 1 |
| G05 | The staging app is attached to the PROD network | `dependency.config_path` points at `../../prod/network` | 1 | 1 |
| G06 | env.hcl says 3 replicas, staging runs 1 | Input name typo is silently ignored; `--inputs-debug` / `render` | 1 | 1 |
| G07 | "Unreadable module directory ../shared" | Module copied alone into `.terragrunt-cache`; use `//` subdir syntax | 2 | 1 |
| G08 | Resources land in us-east-1, region.hcl says eu-central-1 | `generate if_exists = "skip"` vs the module's own provider.tf | 2 | 1 |
| G09 | `run --all` reports a dependency cycle | network <-> app; split the SG unit, inspect with `dag graph` | 2 | 1 |
| G10 | The hotfix vanished after `stack generate` | Hand-edited `.terragrunt-stack/`; move it into values or the unit | 2 | 1 |
| G11 | Nightly `run --all` fails 1 in 3 with Throttling | `errors { retry }`; guard: no blanket ignore | 2 | 2 |
| G12 | Upgrade to 1.2.1 rejects our `exclude` | `exclude if` referencing dependency outputs; use a feature flag | 2 | 2 |
| G13 | A staging destroy would also hit the shared network | Queue/filter scoping (spike-dependent) | 3 | 2 |
| G14 | Parallel init corrupts the plugin cache | `TF_PLUGIN_CACHE_DIR` + `run --all`; use `--provider-cache` (spike-dependent) | 2 | 2 |

**X - Pipeline, security & ops**

| ID | Ticket | Root cause / fix | Lvl | W |
|---|---|---|---|---|
| X01★ | Security: DB password in plaintext in state | ephemeral + `value_wo`, rotate; verified absent from the S3 state | 2 | 1 |
| X02 | The pipeline applied a change nobody reviewed | Apply stage re-plans; use `plan -out` + apply the file. Checked by behaviour | 2 | 1 |
| X03 | Drift detector green for weeks while prod drifted | Script ignores exit code 2; use `-detailed-exitcode`. Lab injects drift and runs it | 1 | 1 |
| X04 | `terraform test` red on main after a refactor | Fix the code, not the tests (`untouched tests/`) | 2 | 1 |
| X05 | `terraform.tfvars` with keys committed | Move to env / ephemeral; history note | 1 | 2 |

## 5. Build plan (phases with gates; mirrors kubernetes-lab §4)

| Phase | Deliverable | **Gate** |
|---|---|---|
| 0. Spike + skeleton | `terra-labs/PLAN.md` (this plan in house style), `versions.env`, `lib/{common,fetch,tf}.sh`, `./lab build/doctor/up/down`, moto image, provider mirror, sha256 checks (the gap k8s left open) | Proven on this host: (a) AWS provider 6.x apply/destroy on moto for s3 + versioning, dynamodb, iam, vpc/subnet/sg (+rules), ssm (`value_wo`), sqs; (b) S3 backend `use_lockfile` blocks a second writer on moto, **else fall back to a DynamoDB lock (moto) or the pg backend for S01**; (c) `AWS_ENDPOINT_URL` honoured by provider + backend + Terragrunt `backend bootstrap`; (d) `init` works with the network blocked (`HTTPS_PROXY=127.0.0.1:9`); (e) docker provider vs Docker 29; (f) disk ≤ 3 GB. Results logged in PLAN.md "Phase 0 result" |
| 1. Framework + 3 pilots | `./lab` full CLI, workspace git, verify toolkit, selftest; pilots S01, G04, X01 | `./lab selftest S01 G04 X01`: broken:ok fixed:ok, each start ≤ 30 s |
| 2. Learn track | L01-L14 (+L15 if the spike allows) | `selftest learn` green |
| 3. Wave 1 incidents | Remaining 34, built domain by domain (S, D, C, P, M, G, X) | `selftest wave1` green; second `plan` after solve = no changes; `./lab stop` leaves no `tfl-*` containers |
| 4. Docs | `README.md`, `docs/CATALOG.md` (ID / Ticket / Lvl / Needs / Emulation / Verify, with a spoiler banner), `docs/FAULTS.md` (techniques, build your own, what the lab does NOT do), `docs/INTERVIEW-QUESTIONS.md` (~60 TF/TG questions, (J)/(M)/(S), linked to scenarios) | Links valid, every catalog row has a scenario |
| 5. Wave 2 | 12 incidents marked W2 + backlog (`./lab interview`: 3 random tickets, 45 min, scored) | `selftest all` green |

## 6. Risks & mitigations

| Risk | Mitigation |
|---|---|
| moto lacks an API or attribute the AWS provider reads | Phase 0 lists the supported resources; scenarios only use those, and docker/local providers carry the rest |
| moto ignores `If-None-Match` (no native lock) | DynamoDB lock in moto or the pg backend for lock scenarios; noted in FAULTS.md |
| AWS provider size (~700 MB unpacked) | One plugin cache, plus Terragrunt `--provider-cache`; only one AWS major mirrored (P02 needs only constraint resolution, not a 5.x binary) |
| Docker Hub flaky | moto image built from the local `python:3.12-slim`; app images already local; pip retries |
| Host tool upgrades change behaviour | Pinned binaries in `cache/bin` take precedence; `doctor` warns on mismatch |
| Spoilers visible in the repo | `.lab/` convention + "Rules of the game" in the README, as in the sibling labs |

## 7. Files to create (all under `terra-labs/`)
```
lab  versions.env  PLAN.md  README.md
lib/common.sh (copied from linux-lab/lib/common.sh: colors, info/ok/warn/die, retry, check/check_eventually/verdict, remember/recall)
lib/fetch.sh  (from kubernetes-lab/lib/fetch.sh + sha256sum -c)    lib/tf.sh (verify toolkit, env for ./lab sh)
infra/moto/Dockerfile  infra/terraformrc.tpl  infra/modules-src/<module>/ (sources for the local git registry, tagged by build)
learn/L01-.../ ... L15     scenarios/S01-.../ ... X05     docs/{CATALOG,FAULTS,INTERVIEW-QUESTIONS}.md
cache/ .state/ workspace/   (runtime; .gitignore for these)
```

## 8. Verification (end to end)
1. `./lab doctor` is all green: pinned versions, docker, moto `/moto-api/` healthy, disk.
2. `./lab selftest all`: for every lab, start -> verify must FAIL -> solve -> verify must PASS. The results table shows durations.
3. Offline proof: `HTTPS_PROXY=http://127.0.0.1:9 ./lab selftest wave1` passes, so there are no network calls.
4. Idempotency: after each solve, `plan_clean` holds on a second run.
5. Leak check: after `./lab stop`, `docker ps -a --filter label=terralab.scenario` is empty and moto is restarted.
6. `shellcheck lab lib/*.sh scenarios/*/.lab/*.sh` is clean.
7. A manual play-through of the 3 pilots: ticket -> sh -> diagnose -> fix -> verify.

---

## 9. Phase 0 result (2026-11-06)

| Gate | Result |
|---|---|
| (a) AWS provider 6.72 on moto 5.2.5 | **PASS**: s3 bucket + versioning + objects, dynamodb, iam role + inline policy, vpc / subnet / sg + both rule styles, ssm incl. `value_wo` + ephemeral `random_password`, sns, kms, logs, secretsmanager. Plans converge (exit 0) |
| (b) S3 native locking on moto | **PASS**: moto honours `If-None-Match: *`; a second writer gets `Error acquiring the state lock` (412). A crafted `.tflock` object is a faithful stale lock; `force-unlock` checks its ID |
| (c) endpoints from env only | **PASS** with `AWS_ENDPOINT_URL=http://localhost:4566`. Lab code is prod-like: `provider "aws" { region = ... }` and a plain `backend "s3"`. **Not** `127.0.0.1`: the provider calls S3 Control at `<account>.<host>` |
| (c') Terragrunt `backend bootstrap` | **PASS** with one knob: `skip_bucket_enforced_tls = true`. Bootstrap attaches an `EnforcedTLS` deny policy and moto cannot evaluate `aws:SecureTransport` (it denies everything, even over real TLS - tested with a lab CA) |
| (d) offline | **PASS**: `init` / `run --all` with `HTTPS_PROXY`/`HTTP_PROXY` pointing at a dead port. Providers come from the filesystem mirror, modules from local git |
| (e) docker provider 4.6 vs Docker 29 | **PASS** with three house rules (§10) - otherwise perpetual diffs |
| (f) disk | **~2.1 GB**: providers 222 MB (zips) + plugin cache 858 MB + binaries 265 MB + downloads 142 MB + moto image 561 MB |

Surprises fixed on the way:
* **moto drops bucket tags sent in `CreateBucketConfiguration`** (AWS added that in 2025; provider 6.x
  uses it) -> perpetual tag diff. Patched in our image: `infra/moto/terralab_moto.py`.
* **SQS is slow on moto**: the provider waits for attribute propagation, 25 s create / 42 s destroy.
  DynamoDB 7 s. Everything else is instant -> labs use SNS instead of SQS.
* **Framework bug caught by pilot X01**: bash ignores `set -e` inside `( ... ) || die`, so a failing
  setup was swallowed. Scenario scripts now run in a fresh `bash -euo pipefail` process (`run_lab_script`).
* Pilot G04: verify probes that create resources must use unique names (the "broken" verify run of
  selftest creates them too).

Phase 1 gate: `./lab selftest S01 G04 X01` -> all `broken:ok fixed:ok`, 38 s / 74 s / 41 s.

## 10. House rules for scenario authors

* AWS = moto at `http://localhost:4566`, account `123456789012`, region `eu-central-1`. Never put
  emulator settings in lab code (except `skip_bucket_enforced_tls` in Terragrunt `remote_state`, with
  the comment). No SQS; DynamoDB only where the story needs it; no S3 lifecycle configurations (the provider waits
  ~55 s for them to settle - real AWS behaviour, too slow for a lab).
* `aws_ssm_parameter.value` is sensitive in provider 6.x - non-secret params use `insecure_value`.
* Docker resources: `networks_advanced { name = docker_network.x.name }` (not `.id`), explicit
  `ipam_config.gateway`, `memory_swap` = `memory`, names `tfl-*`, label `terralab.scenario`.
* Git modules: `git::https://git.acme.example/platform/<repo>.git?ref=vX` - rewritten to
  `.state/git/` by `GIT_CONFIG_GLOBAL` (insteadOf). Publish versions in setup with `publish`.
* Lock files from the mirror only hold `h1:` for linux_amd64 ("Incomplete lock file information" is expected).
* `init -migrate-state` (local->s3, s3->s3) gives the copy a **new lineage** in TF 1.17: prove
  "not recreated" with resource identity (creation dates, IDs, sentinel objects), not lineage.
* Setup: build the past with `apply`/`tg`, inject the fault, `remember` facts (lineage, IDs, leaked
  values). Verify: outcomes on the CI checkout + guard rails; never only grep the code.

## 11. Build log (2026-11-06)

| Phase | Result |
|---|---|
| 0. Spike + skeleton | done - see §9 |
| 1. Framework + pilots | done - `./lab` (build, doctor, list, start, ticket, sh, env, aws, verify, hint, diff, solution, solve, reset, stop, status, up/down, selftest), `lib/{common,tf,fetch}.sh`, pilots S01/G04/X01 |
| 2. Learn track | **L01-L14 done**; L15 (what's new 1.14-1.17) moved to the backlog |
| 3. Wave 1 incidents | **37 done** (S01-S05, D01-D06, C01-C05, P01-P04, M01-M03, G01-G10, X01-X04) |
| 4. Docs | README.md, docs/CATALOG.md (generated from the lab files), docs/FAULTS.md, docs/INTERVIEW-QUESTIONS.md (52 questions) |
| 5. Wave 2 | not started - backlog in docs/CATALOG.md |

**Gate check (2026-11-06)**: `./lab selftest all` with HTTP(S) proxies pointed at a dead port (offline proof):
**51/51 `broken:ok fixed:ok`**, ~33 min. After `./lab stop` no `tfl-*` containers/networks/volumes remain
(except the `tfl-moto` infrastructure container; `./lab down` removes it). `shellcheck` clean.

Deviations from the approved plan (all found while building, all documented in the labs):
* L05's module v1.1.0 adds default encryption instead of a lifecycle rule (lifecycle = 55 s provider wait).
* L13 covers DRY + `feature` + `exclude`; the `errors { retry }` block moved to incident G11 (wave 2).
* M03: Terraform rejects `deprecated` on **root** outputs - the fix is an alias output plus the lesson why.
* P03/G08: re-wiring a provider does not move existing resources - the fixes need `-replace`.
* `plan_clean` reads the plan JSON when `-detailed-exitcode` says 2 (check-block data sources, moves).
* Workspace history: no empty "as found" commit any more - `git show HEAD` shows the breaking change.
* The provider mirror also holds `darwin_arm64` builds of `random` and `local` (P01).
