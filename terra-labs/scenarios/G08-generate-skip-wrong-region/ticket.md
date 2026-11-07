# Notifier settings are in us-east-1 - everything else is in Frankfurt
**INFRA-312** · P2 · Reporter: SRE

The notifier service in eu-central-1 can't find its settings `/prod/notifier/*`. They exist - in
**us-east-1**. `live/prod/env.hcl` says `region = "eu-central-1"`, and `root.hcl` generates the provider
from it. No error, no warning.

Put the settings where they belong, clean up us-east-1, and make sure a module can't silently override
the region again.

**Test**: the settings exist in eu-central-1 and not in us-east-1; `modules/notifier` configures no provider;
the root no longer skips generating the provider; `terragrunt run --all plan` shows no changes.
