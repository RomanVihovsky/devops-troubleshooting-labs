# Collection CI red: `ansible-test sanity` fails on acme.ops.app_flag
**OPS-3233** · P3 · Reporter: collection maintainers

The new module `acme.ops.app_flag` (merged yesterday) works - `ci/smoke.sh` runs it against web1 and is green - but
the collection's sanity job (`ci/sanity.sh` = `ansible-test sanity`) has been red since the merge, so 1.1.0 can't be
published to the private Galaxy. The author's comment on the merge request: *"sanity is just style nitpicks, let's add
`tests/sanity/ignore-2.22.txt`"*. No.

The documentation is the contract our users read: where code and docs disagree, **the docs are right** - the shop
reads `/etc/shop/flags.conf`, and there never was a state `enabled`.

**Test**: `ci/sanity.sh` passes with no sanity ignore entries and no `noqa` / `pylint: disable` comments; `ci/smoke.sh`
passes; the module's default path is `/etc/shop/flags.conf` and `state=enabled` is rejected.
