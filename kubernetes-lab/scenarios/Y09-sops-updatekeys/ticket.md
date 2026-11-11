# alice can't decrypt the prod secrets
**INC-2377** · P3 · Reporter: alice (joined this week)

My age key was added to the repo's `.sops.yaml` on Monday (the "onboarding: alice" commit in `lab/gitops`), but
`sops -d secrets/prod.enc.yaml` still fails for me: *failed to get the data key required to decrypt the SOPS
file ... no identity matched any of the recipients*. My public key is in `workspace/Y09/alice.age.pub`. You
have the team key (`eval "$(./lab env)"` sets `SOPS_AGE_KEY_FILE`).

**Test**: at `main`, `secrets/prod.enc.yaml` decrypts with alice's key **and** with the team key; its content is
unchanged; it is still encrypted (no plaintext password in Git); `.sops.yaml` still lists alice.
