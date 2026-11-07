# Plan after "move uploads into modules/bucket" destroys the uploads bucket
**INFRA-170** · P1 · Reporter: media team (CI bot comment on the PR)

The PR moving our uploads bucket into the shared `modules/bucket` module passed review. The plan in the
PR comment says `3 to destroy` - including `aws_s3_bucket.uploads`, which holds 4 TB of customer uploads
(in the lab: a few files). Merge is blocked.

Keep the module. Nothing may be destroyed or recreated.

**Test**: the bucket and its settings live under `module.uploads` in state; the bucket was not recreated
and still has its files; a CI plan shows no changes.
