## Hint 1
`kubectl -n billing logs <pod> --previous` - the log of the crashed container, not the current one.

## Hint 2
The app tells you which setting it needs. Compare with the `env:` list in the manifest.

## Hint 3
The app reads `DATABASE_URL`; the manifest sets `DB_URL`. Rename it back, apply.
