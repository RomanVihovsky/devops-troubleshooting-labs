# New unit fails to init: "Unreadable module directory"
**INFRA-307** · P3 · Reporter: checkout team

Our first Terragrunt unit `live/dev/checkout` fails at init:
`Unreadable module directory ... ../shared/names: no such file or directory`. Plain
`terraform init` inside `modules/app` works fine. The folder obviously exists.

**Test**: the unit deploys (`/dev/checkout/prefix` = `acme-dev-checkout`); `terragrunt run --all plan` in
`live/` shows no changes; `modules/app` keeps using the shared module.
