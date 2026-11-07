# L10 · Your first Terragrunt unit
**Learn** · root.hcl, include, remote_state + generate, backend bootstrap, hcl fmt, render · ~25 min

`modules/web-config` is a plain Terraform module (no backend, no provider block). Deploy it for
`dev` with Terragrunt 1.x, the way every environment will be wired from now on.

1. `live/root.hcl` (shared by all units): `remote_state` on S3 - bucket `acme-tg-state`,
   key `${path_relative_to_include()}/terraform.tfstate`, `use_lockfile = true`, generated as
   `backend.tf` - and a `generate "provider"` block for `aws` (region `eu-central-1`) with
   `default_tags` carrying `env` from the environment's `env.hcl`.
2. `live/dev/env.hcl`: `locals { env = "dev" }`.
3. `live/dev/web/terragrunt.hcl`: include the root, `source = "../../../modules//web-config"`,
   inputs: `env`, `app_name = "web"`, `settings = { log_level = "debug", feature_x = "on" }`.
4. In `live/dev/web`: `terragrunt backend bootstrap` (1.x no longer creates the bucket silently),
   then `terragrunt apply`. Look at `terragrunt render --json` and run `terragrunt hcl fmt` in `live/`.

**Test**: the state bucket exists (versioned) and holds `dev/web/terraform.tfstate`; the SSM settings and
the assets bucket exist, tagged `env = dev`; the root is `live/root.hcl`; the module has no provider
block; `terragrunt hcl fmt --check` passes; `terragrunt run --all plan` in `live/` shows no changes.
