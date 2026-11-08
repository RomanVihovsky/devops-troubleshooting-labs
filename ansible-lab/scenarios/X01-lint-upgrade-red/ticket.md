# Lint gate red after the runner upgrade to ansible-lint 26 (production profile)
**OPS-330** · P3 · Reporter: platform team

The runner image now ships ansible-lint 26.11; `ci/lint.sh` fails with a dozen findings in `site.yml`. The team
lead's rule: **fix the code** - no `skip_list`/`warn_list`, no `# noqa`, no `.ansible-lint-ignore`, and the
profile stays `production`.

**Test**: `ci/lint.sh` passes with the repo's `.ansible-lint` (profile production, nothing skipped or ignored);
site.yml still converges; web1 still runs nginx with `/etc/acme/app.conf` = `port=8080`.
