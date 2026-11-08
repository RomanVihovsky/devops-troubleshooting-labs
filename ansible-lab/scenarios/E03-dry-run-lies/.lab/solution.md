# Solution - a skipped read makes the dry run lie

**Root cause**: in check mode `command` is skipped (it can't predict its effect). In ansible-core 2.22 the
registered result of a skipped command carries `rc: 0` and an empty `stdout` - so `stdout != app_version` is
always true and every dry run predicts *Stop the app for the upgrade*. (Older versions crashed here with
"has no attribute 'stdout'" - at least that was loud.)

**Fix**: `check_mode: false` on the read-only *Current version* task - it runs for real in dry runs and
gives the later tasks real data.

**Interview notes**
* `check_mode: false` = always run for real; `check_mode: true` = always simulate.
* Only for tasks that don't change anything (reads, queries) - otherwise the dry run isn't dry.
* `command` with `creates`/`removes` supports check mode on its own.
* `ansible_check_mode` lets a task behave differently in dry runs - use it sparingly: skipping the restart in
  check mode makes the dry run blind. A dry run that is always "changed" trains people to ignore it.
