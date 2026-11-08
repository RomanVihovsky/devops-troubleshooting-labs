# acme.ops

Modules for running the ACME shop. Published to the private Galaxy after `ci/sanity.sh` passes.

* `acme.ops.app_flag` - feature flags in `/etc/shop/flags.conf` (since 1.1.0)

CI: `ci/sanity.sh` (`ansible-test sanity`), `ci/smoke.sh` (the module against web1).
