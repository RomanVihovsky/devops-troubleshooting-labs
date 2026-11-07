# Uploads fail in prod: NoSuchBucket "mock-uploads-bucket"
**INFRA-214** · P1 · Reporter: app on-call

The new prod environment went live last week and every upload fails since: the app logs
`NoSuchBucket: The specified bucket does not exist (bucket: mock-uploads-bucket)`.
The real bucket `acme-prod-uploads` exists - it is managed by `live/prod/storage`. The app reads the
bucket name from SSM `/prod/app/uploads-bucket` and is allowed to write where its IAM role says.
Whoever stood prod up did it unit by unit.

Fix it in code, so a brand-new environment can never come up like this again. The uploads bucket
(already holding files) must not be recreated.

**Test**: `/prod/app/uploads-bucket` names the real bucket and the `prod-app` role may write only to
it; `terragrunt run --all plan` in `live/prod` shows no changes; in a brand-new environment, applying
`app` before its `storage` exists **fails** instead of deploying placeholder values.
