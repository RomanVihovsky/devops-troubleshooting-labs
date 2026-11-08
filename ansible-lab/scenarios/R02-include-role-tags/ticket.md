# Release 1.5.0 never reached app1 - the deploy job was green
**OPS-288** · P2 · Reporter: app team

Our release job runs `ansible-playbook site.yml --tags deploy` (see `ci/release.sh`). For 1.5.0 it was green,
but `/opt/app/VERSION` on app1 still says 1.4.0.

The release job must keep using `--tags deploy`, and it must not run the `base` tasks.

**Test**: `ci/release.sh` puts any new version on app1 (VERSION and app.ini); it doesn't run *Base packages*;
the full site.yml converges.
