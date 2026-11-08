# Raised appserver workers to 8 in group_vars - still 2 everywhere
**OPS-240** · P3 · Reporter: web team

Load tests need 8 workers. We set `appserver_workers: 8` in `group_vars/web.yml` (see git log), ran site.yml -
`/etc/acme/appserver.ini` still says `workers = 2` on both nodes. No error. "Just change it in the role" is
not an option: four other teams use the role with their own values.

**Test**: both nodes run with `workers = 8` (from group_vars); other teams can still override every role knob
from their inventory; site.yml converges.
