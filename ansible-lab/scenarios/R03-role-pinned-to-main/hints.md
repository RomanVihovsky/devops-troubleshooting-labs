## Hint 1
`cat requirements.yml` - which version of `acme.banner` does a fresh install get? Compare with
`git ls-remote --tags https://git.acme.example/platform/ansible-role-banner.git`.

## Hint 2
`version: main` is a moving target: every fresh install (every CI run) takes whatever is on the branch today.
`git -C .galaxy/roles/acme.banner log --oneline` (after an install) shows what came in.

## Hint 3
Pin the tag that is deployed (`version: v1.2.0`) and run the pipeline. Upgrade to 2.x later, on purpose,
with `banner_lines` in group_vars.
