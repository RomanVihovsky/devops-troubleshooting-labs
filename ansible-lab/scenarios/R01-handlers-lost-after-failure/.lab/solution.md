# Solution - handlers run at the end of the play, and die with a failed host

**Root cause**: the template changed and notified *Reload nginx*, but handlers run at the end of the play. The
smoke check ran **before** the reload, saw 2.4.0 and failed the host - and a failed host's pending handlers are
dropped. On every re-run the template is unchanged, nothing notifies the handler, the check fails again.

**Fix**:
1. Recover: reload nginx once by hand (or `--force-handlers` on a run that changes the template).
2. Prevent: `meta: flush_handlers` before anything that depends on the new config; `force_handlers: true`
   so that a later failure still runs already-notified handlers.

**Interview notes**
* Handlers: run once, at the end of each `tasks` section / play, in definition order, only on notified hosts.
* `listen:` topics let several handlers react to one notification.
* A lost notification is invisible in later runs - the classic "config deployed but not active" incident.
