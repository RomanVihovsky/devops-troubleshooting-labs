# L12 · Terragrunt Stacks
**Learn** · terragrunt.stack.hcl, unit blocks, values, expansion, autoinclude, stack generate/run/output · ~30 min

Instead of hand-writing one `terragrunt.hcl` per unit and environment, describe the **whole
environment in one file** and let Terragrunt generate the units from a catalog.
`catalog/units/` holds reusable unit templates (look at how `network` reads `values.cidr`).

1. Write `live/dev/terragrunt.stack.hcl`:
   - `unit "network"` from `../../catalog/units/network`, path `network`, `values = { cidr = "10.40.0.0/16" }`;
   - `unit "data"` from `../../catalog/units/data`, path `data`;
   - `unit "app"` from `../../catalog/units/app`, **expanded for two shards** `blue` and `green`
     (path `app-<shard>`), wired to network and data through an `autoinclude` block
     (dependencies with mocks for validate/plan only; inputs incl. `env = "dev-<shard>"`).
2. `terragrunt stack generate` and look inside `.terragrunt-stack/`. Generated, so: never edit it,
   never commit it - check `.gitignore`.
3. `terragrunt stack run --backend-bootstrap -- apply`, then `terragrunt stack output`.

**Test**: security groups `dev-blue-app` and `dev-green-app` live in the stack's VPC and both apps' configs
hold the real IDs; `.terragrunt-stack` is not committed; `stack output` lists network, data and app;
`terragrunt stack run -- plan` on a fresh CI checkout shows no changes.
