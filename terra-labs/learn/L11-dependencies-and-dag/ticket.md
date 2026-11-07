# L11 · Dependencies, mocks and the DAG
**Learn** · dependency blocks, mock_outputs, run --all, dag graph, find/list, Run Report · ~25 min

`live/dev` has three units: `network`, `data`, `app`. Nothing is applied yet (the state bucket exists).
`app` needs the VPC/subnet from `network` and the bucket from `data` - right now it has placeholders.

1. In `live/dev/app/terragrunt.hcl` add `dependency "network"` and `dependency "data"` and wire
   their outputs into `inputs`. Give both `mock_outputs` - **allowed for `validate` and `plan` only**.
2. Before anything exists: `terragrunt run --all plan` in `live/dev` -> works thanks to the mocks.
3. Look at the graph: `terragrunt dag graph`, `terragrunt list --dag`, `terragrunt find --dag --json`.
4. Apply everything in dependency order and keep a Run Report:
   `terragrunt run --all --report-file report.json -- apply` (in `live/dev`).
5. Optional: `terragrunt run --all --filter './app' -- plan` - only one unit.

**Test**: the graph has app -> network and app -> data; `live/dev/report.json` shows all three units
succeeded; app's security group lives in the real VPC and `/dev/app/config` holds the real IDs (no
mocks); mocks are limited to validate/plan; `terragrunt run --all plan` shows no changes.
