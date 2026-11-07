# Standing up staging: init fails with "NoSuchBucket"
**INFRA-288** · P2 · Reporter: platform

Each environment keeps its state in its own bucket (`acme-tg-state-<env>`). Prod's was created two years
ago by an older Terragrunt that created buckets on the fly. Now `terragrunt run --all -- apply` in
`live/staging` fails: `NoSuchBucket: The specified bucket does not exist`. A colleague wants to
`aws s3 mb` it by hand.

Stand up staging. Its state bucket must meet the same standard as prod's (versioning, encryption,
public access blocked).

**Test**: `acme-tg-state-staging` exists with versioning, default encryption and public access blocks;
staging's network is deployed; `terragrunt run --all plan` in `live/` shows no changes.
