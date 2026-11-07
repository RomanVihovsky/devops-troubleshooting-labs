# terra-labs - catalog

> **Spoilers.** The *Root cause* and *Verify* columns give the answers away. Play first: `./lab start <id>`.

Legend: level `•` easy (5-10 min) · `••` medium (10-20 min) · `•••` hard (20-40 min). *Needs*: `moto` = fake AWS
(moto server), `docker` = containers on the host's Docker, `git` = local module registry (`git.acme.example`).
Every lab is checked by `./lab selftest <id>`: it must verify as FAIL when started and PASS after the reference fix.

## L - Learn track (14)

| ID | Lab | Lvl | Needs | Verified by |
|---|---|---|---|---|
| L01 | First apply, fully offline | • | - | random and local pinned with ~&gt;; state has random_pet.name; state has local_file.greeting; out/greeting.txt says Hello, &lt;the pet in state&gt;! ... |
| L02 | Variables done right | • | - | config file got the defaults (port 8080, 2 replicas); token file holds the token; valid staging inputs plan fine; env=qa is rejected ... |
| L03 | A container fleet with for_each | • | docker | tfl-fleet-web and tfl-fleet-static are running; tfl-fleet-api is gone; labels: service=&lt;key&gt;, terralab.scenario=L03; memory limits: web 64 MiB, static 32 MiB ... |
| L04 | Remote state on S3 with native locking | • | moto | acme-tfstate: versioning enabled; acme-tfstate: default encryption aws:kms; acme-tfstate: all public access blocked; inventory state is in s3://acme-tfstate/inventory/terraform.tfstate ... |
| L05 | Modules and versions | •• | moto, git | state: module.media.aws_s3_bucket.this + versioning; state: inline aws_s3_bucket.media is gone; bucket not recreated (same creation date); product images still there ... |
| L06 | Import, generate config, removed | •• | moto | flags checkout/search/recs are in state (for_each); flag values untouched (on/off/on, never rewritten); role legacy-reporting is in state; it is still the same role (not recreated) ... |
| L07 | Lifecycle rules and conditions | •• | moto, docker | terraform plan -destroy is refused (prevent_destroy); banner still says marketing's text; CI plan shows no changes (banner edit ignored); a config_version change replaces the container, not the volume ... |
| L08 | Secrets that never touch state | •• | moto | SSM /checkout/db/password: SecureString, 24+ chars; Secrets Manager checkout/partner-api-key holds the vendor key; DB password is not in the state; API key is not in the state ... |
| L09 | terraform test: unit tests, mocks and integration | •• | moto | terraform test passes in modules/naming; terraform test passes in modules/bucket (unit + integration); tests use expect_failures, mock_provider and a command = apply run; mutant: '_' instead of '-' in names -&gt; naming tests fail ... |
| L10 | Your first Terragrunt unit | • | moto | state bucket acme-tg-state exists and is versioned; state at s3://acme-tg-state/dev/web/terraform.tfstate; SSM /dev/web/log_level=debug, /dev/web/feature_x=on; assets bucket exists, tagged env=dev (default_tags) ... |
| L11 | Dependencies, mocks and the DAG | •• | moto | DAG: app -&gt; network and app -&gt; data; live/dev/report.json: network, data, app succeeded; security group dev-app is in the real VPC; /dev/app/config holds the real VPC and bucket (no mocks) ... |
| L12 | Terragrunt Stacks | •• | moto | SG dev-blue-app is in the stack's VPC; SG dev-green-app is in the stack's VPC; both app configs hold the real VPC and bucket; .terragrunt-stack/ is not committed ... |
| L13 | DRY multi-env with feature flags | •• | moto | no remote_state/generate in unit files; root.hcl + env.hcl exist; terragrunt run --all plan in live/: no changes; Run Report: dev/audit excluded, prod/audit runs; --feature audit=true includes dev/audit ... |
| L14 | A pipeline that deserves trust | ••• | moto | check passes on the clean repo; check fails on bad formatting; check fails on a lint error (unused variable); check fails when the bucket would be replaced ... |

## S - State & backends (5)

| ID | Ticket (symptom) | Lvl | Needs | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| S01 | Every terraform run fails: "Error acquiring the state lock" | • | moto | stale S3 lockfile from a killed CI job | CI plan of stacks/payments succeeds with locking and shows no changes; no lock object left in s3://acme-tfstate; state is the original one (same lineage, not recreated); customer receipts are still there; nothing in the repo disables locking (-lock=false) |
| S02 | After the "backend tidy-up", plan wants to create everything | • | moto | backend key changed without migrating the state | CI plan with key prod/billing/terraform.tfstate shows no changes; old key billing/terraform.tfstate is gone; export bucket not recreated, invoices still there; no duplicates: still one SNS topic, parameters never rewritten |
| S03 | Plan wants to create things that exist - after someone "fixed" the state | •• | moto | restore the state from a bucket version | CI plan of stacks/notifications shows no changes; state knows the refunds topic, role and parameter; they are the originals (same role, one topic, parameter untouched) |
| S04 | Two pipelines keep deleting each other's resources | ••• | moto | two roots, one state key | CI plan of stacks/search shows no changes; CI plan of stacks/recs shows no changes; separate states (different keys); search topic and parameters untouched; recs parameters and topic exist |
| S05 | CI: terraform init fails with "Missing required argument" | • | moto | partial backend config file renamed, CI script not updated | ci/plan.sh prod on a fresh checkout: exits 0 (no changes); it really used the prod state (prod/ledger); backend file keeps its new name (prod.s3.tfbackend); an unknown env fails instead of planning without a backend |

## D - Drift, import & refactoring (6)

| ID | Ticket (symptom) | Lvl | Needs | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| D01 | Refactor PR wants to recreate all 6 web containers | •• | docker | moved blocks for count -&gt; for_each | state is keyed by site (docker_container.web[\; all six containers are the originals; CI plan of web/ shows no changes |
| D02 | Plan after "move uploads into modules/bucket" destroys the uploads bucket | • | moto | moved blocks into a module | bucket, versioning and public access block live under module.uploads; bucket not recreated, uploads still there; CI plan of stacks/media shows no changes |
| D03 | The nightly apply reverted ops' 3 a.m. hotfix - and will tonight again | •• | moto | codify the hotfix (change + import) | max-connections is 400; reporting rule 10.30.0.0/16:5432 exists (exactly once); the reporting rule is managed by Terraform (in state); security group is the same one; CI plan of stacks/orders-db shows no changes |
| D04 | Apply fails: BucketAlreadyOwnedByYou (acme-analytics-exports) | • | moto | adopt the hand-made bucket with an import block | bucket and versioning are in state; same bucket, exports still there; versioning is enabled; CI plan of stacks/analytics shows no changes |
| D05 | PR "hand the ML datasets bucket to the data team" would delete it | • | moto | removed { destroy = false } | datasets bucket + versioning no longer in this state; bucket still exists with its files (same bucket); versioning still enabled; CI plan of stacks/platform-shared shows no changes |
| D06 | Every apply "changes" the db security group - reporting loses DB access every other run | •• | moto | one owner per rule | app rule 10.50.1.0/24:5432 exists; reporting rule 10.60.0.0/16:5432 exists; two consecutive CI plans show no changes; same security group |

## C - Language & config (5)

| ID | Ticket (symptom) | Lvl | Needs | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| C01 | DR region bootstrap fails: "Invalid for_each argument" | •• | moto | for_each keys must be known at plan time | dr: 3 log buckets, each with a public access block; CI plan of prod shows no changes; CI plan of dr shows no changes; prod buckets are the originals |
| C02 | "Error: Cycle" after adding one security group rule | •• | moto | break the cycle with a separate rule resource | app allows 8080 from the lb group; lb allows egress 8080 to the app group; both security groups are the originals; CI plan of stacks/edge shows no changes (no cycle) |
| C03 | Staging apply created prod-* resources (and staging's are gone) | • | moto | a stray *.auto.tfvars wins over terraform.tfvars | staging parameters and topic are back; no prod-* resources in this account; no *.auto.tfvars overriding env; CI plan of stacks/web-config shows no changes |
| C04 | Deploy fails: 'The container name "/tfl-api" is already in use' | •• | docker | unique names for create_before_destroy | one api container: APP_COLOR=green, alias api on tfl-api-net; a color change is still create-before-destroy; CI plan of stacks/api shows no changes |
| C05 | Fresh environments fail randomly: "network tfl-jobs-net not found" | • | docker | a reference, not a string | graph: workers depend on the network; existing worker containers not recreated; CI plan of stacks/worker shows no changes |

## P - Providers & init (4)

| ID | Ticket (symptom) | Lvl | Needs | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| P01 | CI: "doesn't match any of the checksums previously recorded in the dependency lock file" | • | - | lock hashes for every platform you run on | CI init + plan of stacks/config-bundle: no changes; lock file has 2+ platform hashes for random and local; versions unchanged: random 3.9.1, local 2.9.1; lock file committed |
| P02 | Renovate PR breaks init: "no available releases match the given constraints" | •• | moto, git | provider constraints across the module tree | CI init + plan: no changes; both modules from tf-module-topic &gt;= v2.0.0; topics KMS-encrypted, subscriptions survived |
| P03 | DR audit: the "Ireland" replica bucket is in Frankfurt | •• | moto | pass the aliased provider to the module | acme-media-replica is in eu-west-1; primary unchanged (same bucket, still in eu-central-1, files there); module.replica is wired to the DR region; CI plan of stacks/media-dr shows no changes |
| P04 | "Unsupported Terraform Core version" after vendoring the tags module | • | moto | an over-tight required_version | CI init + plan of stacks/shop: no changes; module keeps a constraint: allows 1.9-1.17, refuses 2.x |

## M - Modules (3)

| ID | Ticket (symptom) | Lvl | Needs | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| M01 | CI plan shows changes nobody made - locally the plan is clean | • | moto, git | never point a module at a branch | CI plan (fresh checkout) shows no changes; module pinned to v1.2.0 (tag or its commit); deployed values unchanged (log_level=info, no tracing) |
| M02 | Upgrading tf-module-pgbox to v2.0.0 destroys the database volume | ••• | docker, git | ship moved blocks inside the module | inventory uses tf-module-pgbox &gt;= v2.0.1; that release upgrades a v1 user with no changes (moved blocks in the module); volume and container are the originals; CI plan of stacks/inventory-db shows no changes |
| M03 | Payments' pipeline broke after our network release: "Unsupported attribute" | •• | moto | outputs are an API; keep an alias | CI plan of stacks/network shows no changes; CI plan of stacks/payments-api shows no changes; network state exposes app_subnet_id and subnet_id (same value); stacks/payments-api unchanged; the old output is marked deprecated |

## G - Terragrunt 1.x (10)

| ID | Ticket (symptom) | Lvl | Needs | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| G01 | Every Terragrunt pipeline is red since the runner image upgrade | • | moto | migrate scripts to the Terragrunt 1.x CLI | ci/plan-all.sh prod plans all units and exits 0; it fails when a unit fails; 1.x CLI only (no run-all, --terragrunt-*, TERRAGRUNT_*) |
| G02 | Standing up staging: init fails with "NoSuchBucket" | • | moto | terragrunt backend bootstrap | acme-tg-state-staging: versioned, encrypted, private; staging network deployed (state in its bucket); terragrunt run --all plan in live/: no changes |
| G03 | After "rename root terragrunt.hcl to root.hcl", nothing plans any more | • | moto | tell find_in_parent_folders which file to find | terragrunt run --all plan in live/: no changes; no root live/terragrunt.hcl |
| G04 | Uploads fail in prod: NoSuchBucket "mock-uploads-bucket" | •• | moto | unrestricted mock_outputs were used by `apply` | SSM /prod/app/uploads-bucket = acme-prod-uploads; prod-app role may write only to acme-prod-uploads; terragrunt run --all plan in live/prod: no changes; uploads bucket kept its files (not recreated); a brand-new env refuses to apply app with mock outputs |
| G05 | Security scan: staging app runs inside the PROD VPC | • | moto | wrong dependency path | staging-app is in the staging VPC, config points at staging; prod security group is the original; terragrunt run --all plan in live/: no changes |
| G06 | env.hcl says 3 replicas, staging runs with 1 | • | moto | an input that matches no variable | /staging/web/replicas = 3; the value comes from env.hcl (render shows inputs.replicas = 3); terragrunt run --all plan in live/: no changes |
| G07 | New unit fails to init: "Unreadable module directory" | •• | moto | the // in terraform.source | /dev/checkout/prefix = acme-dev-checkout; terragrunt run --all plan in live/: no changes; modules/app still uses ../shared/names |
| G08 | Notifier settings are in us-east-1 - everything else is in Frankfurt | •• | moto | generate with skip + a module that brings its own provider | settings exist in eu-central-1; nothing left in us-east-1; modules/notifier configures no provider; root.hcl no longer skips the generated provider; terragrunt run --all plan in live/: no changes |
| G09 | Security change broke the prod pipeline: "dependency cycle" | •• | moto | a third unit owns the relationship | db SG allows 5432 from the app SG; the DAG has no cycle (dag graph works); db security group is the original; terragrunt run --all plan in live/prod: no changes |
| G10 | Last night's scale-up hotfix (4 replicas) vanished overnight | •• | moto | change the stack, not the generated units | /prod/web/replicas = 4; fresh checkout: terragrunt stack run -- plan shows no changes; .terragrunt-stack/ is not committed |

## X - Pipelines, security & testing (4)

| ID | Ticket (symptom) | Lvl | Needs | Root cause (spoiler) | Verified by |
|---|---|---|---|---|---|
| X01 | Security finding: DB master password readable in Terraform state | •• | moto | ephemeral value + write-only argument, then rotate | CI plan of stacks/orders-db shows no changes; leaked password is not in the current state; the new password is not in the state either; password was rotated (new value, 20+ chars); /orders/db/password is still a SecureString; no nonsensitive() workaround in the code |
| X02 | Postmortem action: the pipeline applied a change nobody reviewed | •• | moto | review and apply the same saved plan | apply ships exactly the reviewed change (not the later commit); apply without a reviewed plan fails and changes nothing |
| X03 | Drift detector green for 6 weeks - prod limit was changed by hand | • | moto | a drift detector must refresh | drift.sh: 2 with the hand-made change, 0 without |
| X04 | main is red: terraform test fails after "simplify pricing" | •• | - | the tests were right | terraform test passes in modules/pricing; tests/ unchanged |

## Totals

| Track | Labs |
|---|---|
| Learn | 14 |
| S - State & backends | 5 |
| D - Drift, import & refactoring | 6 |
| C - Language & config | 5 |
| P - Providers & init | 4 |
| M - Modules | 3 |
| G - Terragrunt 1.x | 10 |
| X - Pipelines, security & testing | 4 |
| **All** | **51** |

## Backlog (wave 2, see PLAN.md §4)

S06 DynamoDB -> S3 lockfile migration · S07 workspace mix-up · D07 timestamp() in triggers · C06 object type
without optional() · C07 nonsensitive() leak · P05 hard-coded profile · P06 module not installed ·
G11 `errors { retry }` for throttling · G12 `exclude` on dependency outputs · G13 destroy scope · G14 plugin
cache race (`TF_PLUGIN_CACHE_DIR` + `run --all`) · X05 committed tfvars secrets · L15 what's new 1.14-1.17 ·
`./lab interview` (3 random tickets, timer, score).
