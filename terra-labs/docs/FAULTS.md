# How the faults are made (and how to build your own)

Every incident replays a **real history**: `setup.sh` runs Terraform/Terragrunt against the fake AWS
exactly as "the team" did, commits that history into `workspace/`, then makes the one mistake the ticket
is about. Nothing is mocked text - locks, state versions, drift and lineage are genuine.

## Techniques

| Area | Technique | Used by |
|---|---|---|
| State & locking | a crafted `<key>.tflock` object (the same JSON Terraform writes with `use_lockfile`) from a "killed runner" | S01 |
| | backend `key` changed in a later commit, old state left in place | S02 |
| | `terraform state push -force` of an older copy over a versioned state object | S03 |
| | two roots with the same backend key, applied alternately | S04 |
| | partial backend file renamed in a cleanup commit, CI script not updated | S05 |
| Refactoring | code applied in its "before" shape (`.lab/before/`), then the refactor commit without `moved` | D01, D02, M02 |
| Drift | `aws ...` changes after apply (console hotfix), hand-made resources Terraform doesn't know | D03, D04, X03 |
| Flapping | inline security group rules + a separate rule resource, applied twice | D06 |
| Language | committed `*.auto.tfvars`, unknown `for_each` keys in a new env, cycles, string instead of reference | C01-C05 |
| Providers | lock file regenerated for `darwin_arm64` only (mirror has both platforms) | P01 |
| | module versions with incompatible provider constraints in the local git registry | P02 |
| | aliased provider never passed to a module | P03 |
| Modules | `?ref=main` + a later untagged commit; renamed resources in a major release | M01, M02 |
| Terragrunt | legacy 1.0 CLI in scripts, missing bootstrap, root rename, mocks without allow-list, wrong `config_path`, input typos, missing `//`, `if_exists = "skip"`, cycles, hand-edited `.terragrunt-stack` | G01-G10 |
| Pipelines | re-planning apply stage, `-refresh=false` drift detector, a refactor that breaks tests | X02-X04 |

## The environment, honestly

| Piece | What it is | Fidelity notes |
|---|---|---|
| AWS | moto 5.2 server (`terralab/moto:1`), `http://localhost:4566`, account `123456789012` | Real API shapes for S3 (incl. conditional writes -> native locking), IAM, EC2/VPC/SG rules, SSM, SNS, KMS, Secrets Manager, CloudWatch Logs, DynamoDB. In-memory: `./lab stop` = empty account |
| moto patch | `infra/moto/terralab_moto.py` | AWS provider 6.x sends bucket tags inside `CreateBucketConfiguration` (S3 API addition, 2025); moto 5.2 ignored them -> perpetual tag diff. The patch stores them |
| Docker | the host's Docker, unprivileged containers from local images | Real create/replace/name-clash semantics |
| Module registry | `https://git.acme.example/...` rewritten to `.state/git/*.git` via `GIT_CONFIG_GLOBAL` `url.insteadOf` | Real `git::` sources, tags, pushes |
| Providers | `cache/providers` filesystem mirror + shared plugin cache, via `TF_CLI_CONFIG_FILE` | Lock files hold `h1:` hashes of the mirror's platforms only |

Known differences from real AWS (all handled in the labs):
* moto denies every request to a bucket with Terragrunt's `EnforcedTLS` policy (it can't evaluate
  `aws:SecureTransport`), so lab `remote_state` blocks set `skip_bucket_enforced_tls = true` - commented.
* The AWS provider waits for SQS (25 s create, 42 s destroy) and lifecycle configurations (~55 s) to
  "settle" - real behaviour, too slow for labs, so labs avoid them.
* Changing a provider's region doesn't move existing resources (true on AWS too) - P03/G08 teach `-replace`.

## Things Terraform did that surprised us (they became lab content)

* `init -migrate-state` gives the copy a **new lineage** (TF 1.17) -> "not recreated" is proven with
  resource identity (creation dates, IDs, sentinel objects), never with lineage.
* Data sources in `check` blocks make `plan -detailed-exitcode` return **2** with nothing to change.
  The lab's `plan_clean` therefore reads the plan JSON. (L07, X03 notes)
* Pending `moved` blocks also make `-detailed-exitcode` return 2 (M02 judges the plan JSON).
* `deprecated` works on module outputs/variables, but a **root** output with `deprecated` is an error. (M03)
* Importing an SSM `String` parameter fills `value`, not `insecure_value` -> config with
  `insecure_value` turns the import into "import + update". (L06)
* A new Terragrunt unit without a lock entry re-installs into the shared plugin cache while parallel
  `run --all` units read it -> "cached package does not match the checksums". The lab sets
  `plugin_cache_may_break_dependency_lock_file = true`; incident G14 (backlog) will teach it.

## Build your own scenario

```
scenarios/X09-short-symptom/
  scenario.yaml    id, title, kind: incident|learn, level 1-3, domain, needs: [moto,docker,git], wave, est
  ticket.md        "# Title" / "**ID** · P1 · Reporter: ..." / symptoms / constraints / **Test**: ...
  hints.md         ## Hint 1..3 (from "where to look" to "what to type")
  files/           the repo as found (copied into workspace/ before setup)
  .lab/setup.sh    build the past (apply, ws_commit "msg" "author"), then inject the fault
  .lab/verify.sh   check "desc" cmd... ; verdict      (runs in the CI checkout, no set -e)
  .lab/solve.sh    reference fix (selftest)            (runs in workspace/, set -euo pipefail)
  .lab/solution.md "# Solution - <root cause>", Root cause, Diagnose, Fix, Interview notes
```
Scripts run in a fresh `bash` with `lib/common.sh` + `lib/tf.sh` loaded, the lab environment exported,
`$WS` (workspace), `$CI` (CI checkout, verify only), `$SCN` (the scenario dir) and `$STATE_DIR`.

Helpers you will use:

| Setup / solve | Verify |
|---|---|
| `state_bucket [name]` | `plan_clean <dir>` / `plan_rc` (JSON-aware, cached) |
| `apply <dir> [args]`, `destroy`, `tf <dir> ...` | `tg_plan_clean <dir>` (`run --all plan`) |
| `tg <dir> ...`, `tg_apply_all <dir>` | `in_state` / `not_in_state` / `state_has_re` |
| `publish <repo> <tag\|-> <src> [msg]` (module registry) | `same_bucket`, `same_ctr`, `object_exists`, `ssm_value` |
| `ws_commit "msg" ["author"]` | `untouched <path>` (vs "as found"), `ws_has <regex>`, `not <cmd>` |
| `remember k v`, `remember_bucket`, `remember_ctr` | `recall k`, `CI_INIT_ARGS[dir]`, `CI_PLAN_ARGS[dir]` |
| `lab_setenv NAME value` (exported in `./lab sh` and verify) | `check_eventually <s> "desc" cmd` |

House rules (see PLAN.md §10): no emulator settings in lab code; docker resources named `tfl-*` with the
`terralab.scenario` label, `networks_advanced` by `.name`, explicit IPAM gateway, `memory_swap`; probes in
verify that create resources use unique names (selftest runs verify on the broken state too).

Then: `./lab selftest X09` must print `broken:ok fixed:ok`, and add the row to the catalog
(`docs/CATALOG.md` is generated from the files: `python3 tools/catalog.py .`; the README tables are edited by hand).

## What the lab deliberately does NOT do

* No real cloud, no credentials, no internet after the build.
* No privileged containers, no host networking, nothing outside `tfl-*`.
* No HCP Terraform / Terraform Stacks (HCP) / Sentinel - their concepts appear as notes.
* No OpenTofu track (decision of 2026-11-06); Terragrunt runs Terraform via `TG_TF_PATH=terraform`.
