# L02 · Variables done right
**Learn** · types, defaults, validation, sensitive · ~20 min

`app-config/` renders a service config file from variables - and accepts anything. Make the
interface strict, so mistakes fail at `plan` time instead of in production.

1. `env`: a string that must be one of `dev`, `staging`, `prod`.
2. `service`: an **object** with `name` (string), and optional `port` (default `8080`),
   `replicas` (default `2`), `tags` (map of strings, default `{}`) - use `optional(type, default)`.
3. Validation on `service`: name matches `^[a-z][a-z0-9-]{2,20}$`; port between 1024 and 65535;
   and **in prod, replicas must be at least 3** (a validation may refer to other variables since TF 1.9).
4. `api_token`: required, sensitive, no default. Its value is already in your shell as
   `TF_VAR_api_token`. Write it to `out/<env>-<name>.token` with `local_sensitive_file`.
5. `terraform apply -var-file=env/staging.tfvars`. Try a few bad values with `-var` to watch them fail.

**Test**: with `env/staging.tfvars` the config file gets the defaults (port 8080, 2 replicas) and the token
file holds the token; bad env / name / port and prod-with-1-replica all fail at plan; a CI plan with
`env/staging.tfvars` shows no changes.
