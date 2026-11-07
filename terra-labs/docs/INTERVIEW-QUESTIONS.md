# Terraform & Terragrunt interview questions

Level: (J) junior · (M) mid · (S) senior. Each answer lists the key points a good answer contains;
`[S01]` = the lab where you practise it.

## Core workflow & language

1. **(J) What do `init`, `plan`, `apply` each do, and what is in `.terraform/`?** - init: backend, providers
   (lock file), modules; plan: refresh + diff config vs state; apply: executes a plan. `.terraform/` caches
   providers, modules, backend config - never commit it. [L01]
2. **(J) What is the dependency lock file and why commit it?** - exact provider versions + package hashes
   per platform; reproducible, supply-chain safe; `providers lock -platform=...` for other OSes. [L01, P01]
3. **(J) `-detailed-exitcode`?** - 0 no changes, 1 error, 2 changes. Why CI needs it; gotchas: `check` data
   sources and pending `moved` return 2 too. [L01, L07, X03]
4. **(J) Variable precedence?** - `TF_VAR_` < `terraform.tfvars` < `.tfvars.json` < `*.auto.tfvars` <
   `-var`/`-var-file`. [L02, C03]
5. **(M) `count` vs `for_each`?** - identity by index vs key; removing an element; keys must be known at plan
   time; convert with `moved`. [L03, D01, C01]
6. **(M) "Invalid for_each argument... known only after apply" - why, and the fix?** - keys derived from
   computed attributes; key by static input; `-target` is not a design. [C01]
7. **(M) Implicit vs explicit dependencies?** - references build the graph; `depends_on` is coarse and makes
   data sources read late; hard-coded names cause races. [C05]
8. **(M) What causes "Error: Cycle" and how do you break it?** - mutual references; extract the relationship
   into a third resource (separate rule). [C02, G09]
9. **(M) `validation` vs `precondition` vs `postcondition` vs `check`?** - inputs / assumptions / guarantees
   / continuous warnings; cross-variable validation since 1.9. [L02, L07]
10. **(M) `lifecycle` arguments and their traps?** - `create_before_destroy` + unique names,
    `prevent_destroy` limits, narrow `ignore_changes`, `replace_triggered_by` + `terraform_data`. [L07, C04]
11. **(S) A plan is never clean. How do you debug a perpetual diff?** - read which attribute flips;
    provider normalisation; two resources owning the same thing (inline vs separate rules); fix ownership,
    don't `ignore_changes`. [D06, L03]

## State

12. **(J) Why remote state? What makes a good backend?** - sharing, locking, versioning, encryption, access
    control; S3 + `use_lockfile` (1.10+), DynamoDB locking deprecated. [L04]
13. **(J) How does S3 native locking work?** - `<key>.tflock` via conditional `PutObject` (`If-None-Match`). [S01]
14. **(M) A lock is stuck. Steps?** - read Lock Info (who/when/op/ID), prove the holder is dead,
    `force-unlock <ID>`; never `-lock=false`. [S01]
15. **(M) `-migrate-state` vs `-reconfigure`?** - copy vs ignore the existing state; changing keys is a
    migration; when `-reconfigure` is *right* (S04). [S02, S04, L04]
16. **(M) Serial and lineage?** - write counter vs history identity; why `state push` refuses lower serials;
    migration gives a new lineage in recent versions. [S03]
17. **(S) Someone ran `state push -force` with an old copy. Recover.** - versioned bucket, pick the version
    before the push by content, push it back; import as fallback. [S03]
18. **(S) Two stacks share a state key. Symptoms and fix?** - flapping destroys; separate keys with an *empty*
    new state; split state if both own resources. [S04]
19. **(M) What is in state that shouldn't be readable by everyone?** - secrets (sensitive values are plain
    text); restrict bucket access; ephemeral values. [X01, L08]

## Refactoring, import, drift

20. **(J) `moved` vs `terraform state mv`?** - reviewable/repeatable in code vs one-off CLI. [L05, D01, D02]
21. **(M) How do you bring an existing resource under Terraform?** - `import` block (+ `for_each`, 1.7+),
    `-generate-config-out`, read the plan for "import + update". [L06, D04, D03]
22. **(M) How do you stop managing something without deleting it?** - `removed { lifecycle { destroy = false } }`. [D05, L06]
23. **(M) Drift: detect, then revert or codify?** - nightly refreshed plan / `-refresh-only`; incident
    hotfixes get codified before the next apply. [D03, X03]
24. **(S) A module major version renames resources. As module author?** - ship `moved` blocks inside the
    module, patch release, test upgrades vN -> vN+1 for an empty plan. [M02]

## Providers & modules

25. **(J) `~> 6.0` vs `~> 6.0.0` vs `>= 6.0`?** - minor vs patch vs open-ended; modules state minimums, root
    sets the ceiling. [P02, P04]
26. **(M) "no available releases match the given constraints"?** - one provider version for the whole tree;
    `terraform providers` shows who wants what. [P02]
27. **(M) Multiple regions/accounts?** - provider aliases, `providers = {}` into modules,
    `configuration_aliases`; AWS provider 6 per-resource `region`. [P03, G08]
28. **(M) Why must reusable modules not configure providers?** - caller owns config; breaks
    `count`/`for_each` on modules; Terragrunt `generate` clashes. [G08]
29. **(M) How do you pin a git module, and why not a branch?** - `?ref=` tag or SHA; branches float,
    tags can move. [M01, L05]
30. **(S) Changing a module output that other stacks read?** - outputs are an API; add new, keep alias,
    remove later; `deprecated` only for module outputs; `terraform_remote_state` coupling vs SSM. [M03]

## Secrets & security

31. **(J) Does `sensitive = true` keep a value out of state?** - no; only output redaction. [X01, L02]
32. **(M) Ephemeral resources/variables and write-only arguments?** - never persisted; `*_wo` +
    `*_wo_version` for rotation; where ephemeral values may flow. [L08, X01]
33. **(M) Secrets in CI logs?** - `nonsensitive()`, `terraform output -json`, plan artifacts are sensitive. [X01]
34. **(S) Leaked secret in state - full remediation?** - rotate, stop persisting, old state versions,
    access to the bucket, audit. [X01]

## Testing & pipelines

35. **(M) What does `terraform test` give you?** - run blocks (plan/apply), `expect_failures`,
    `mock_provider`, overrides; unit vs integration files. [L09, X04]
36. **(S) How do you know your tests are good?** - mutation: break the code, tests must fail. [L09]
37. **(M) Design a Terraform pipeline.** - fmt, validate, lint, test, plan -out, policy on plan JSON,
    review, apply the saved plan, drift detection, locking & serialisation. [L14]
38. **(M) Why apply a saved plan?** - exactly what was reviewed; stale plan protection. [X02]
39. **(S) Policy as code?** - plan JSON (`resource_changes[].change.actions`), OPA/Conftest/Sentinel/Terraform
    Policy (1.17 GA); deletes/replacements only visible in the plan. [L14]
40. **(M) A test fails after a refactor. Change the test?** - only if the requirement changed; otherwise
    the code. [X04]

## Terragrunt 1.x

41. **(J) What problem does Terragrunt solve?** - DRY backend/provider config, many small states, DAG
    orchestration, dependencies between units. [L10, L13]
42. **(J) `root.hcl` vs a root `terragrunt.hcl`?** - root is not a unit; `find_in_parent_folders("root.hcl")`. [L10, G03]
43. **(M) `dependency` + `mock_outputs` - and the danger?** - mocks for plan of unapplied deps; restrict with
    `mock_outputs_allowed_terraform_commands`. [L11, G04]
44. **(M) What changed in the 1.0 CLI?** - `run --all`, no `--terragrunt-` prefix, `TG_*`, `hcl fmt`,
    `dag graph`, `render`, `backend bootstrap`, `--filter`. [G01, G02]
45. **(M) Why `//` in `terraform.source`?** - copy root vs working dir in `.terragrunt-cache`. [G07]
46. **(M) An input has no effect. Why no error?** - inputs are `TF_VAR_*`, unknown ones are ignored;
    `render --json`, `--inputs-debug`. [G06]
47. **(M) Stacks: what are `unit`, `values`, `.terragrunt-stack`?** - generated units from a catalog;
    never edit or commit generated output; `expansion`/`autoinclude` in 1.2. [L12, G10]
48. **(M) Feature flags and `exclude`?** - per-run toggles, queue exclusion visible in the Run Report;
    not a hard ban for single-unit runs. [L13]
49. **(S) DRYing copy-pasted units without moving state?** - backend keys are identity;
    `path_relative_to_include()` must reproduce them or migrate. [L13, S02]
50. **(S) Dependency cycle between units?** - extract the relationship into its own unit. [G09]
51. **(S) Parallel `run --all` and the provider plugin cache?** - concurrent installs into a shared cache
    corrupt it; use Terragrunt's provider cache or pre-warmed caches. [FAULTS.md, G14 backlog]
52. **(S) How do you keep CI fast with 200 units?** - `--filter-affected`/`--filter`, provider cache,
    parallelism, Run Reports, plan only what changed.
