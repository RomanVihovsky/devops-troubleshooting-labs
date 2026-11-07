# SSH key login stopped working
**LNX-113** · P1 · Reporter: CI team

The CI runner (`lnx-client`, user `ci`) deploys with `ssh deploy@10.77.0.10`. Since
yesterday: `Permission denied (publickey)`. Nobody changed the key, and
`/home/deploy/.ssh/authorized_keys` still contains it. Security forbids turning off
`StrictModes` or enabling password auth.

Try it: `./lab sh client ci`, then `ssh deploy@10.77.0.10`.

**Test**: `ci@client` can `ssh deploy@10.77.0.10` with its key, `StrictModes` stays on.
