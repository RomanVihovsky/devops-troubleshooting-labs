## Hint 1
When does a handler run? Not when it is notified - at the end of the play (or at a flush). What happened to
the pending notification when the smoke check failed?

## Hint 2
A failed host is removed from the play: its pending handlers are **dropped**. The next run finds the template
unchanged, so nobody notifies the handler again. The node is stuck on the old config until someone reloads it.

## Hint 3
Two things: reload nginx once by hand (`ansible web -b -m ansible.builtin.service -a "name=nginx state=reloaded"`),
and add `- ansible.builtin.meta: flush_handlers` **before** the smoke check, so the reload happens before it is
tested. (`force_handlers: true` is a good extra - alone it doesn't make the check pass in one run.)
