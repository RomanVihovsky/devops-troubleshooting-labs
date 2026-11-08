# New CI idempotence gate fails: app1 reports changed=5 on every run
**OPS-301** · P3 · Reporter: platform team

We added `ci/idempotence.sh` (run twice, the second run must report `changed=0`). The app node play fails
it on every run, although nothing changes on the node. Making the gate pass by declaring tasks "never changed"
is not acceptable - real drift must still show up as a change.

**Test**: a second run changes nothing; drift (a deleted symlink, a deleted user) is repaired **and reported as
changed**; ansible-lint's `no-changed-when` / `command-instead-of-*` rules pass; site.yml converges.
