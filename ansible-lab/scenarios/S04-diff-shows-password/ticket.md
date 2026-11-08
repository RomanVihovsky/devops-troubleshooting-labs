# PR bot posted the DB password - old and new - in a comment
**SEC-97** · P1 · Reporter: security

`ci/pr-check.sh` runs `--check --diff` and posts the output on the pull request. After the last DB password
rotation (the secret store export lands in `.secrets/db.json` on the runner), the comment showed
`-password = <old>` / `+password = <new>`.

Reviewers still need to see *that* the DB config would change.

**Test**: after a password rotation the PR check's output (text and JSON) contains neither password, but still
reports *DB client config* as changed; the real deploy writes the current password; site.yml converges.
