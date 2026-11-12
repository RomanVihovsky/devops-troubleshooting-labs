# invoicer's logs are empty
**INC-2535** · P3 · Reporter: on-call

`kubectl -n billing2 logs deploy/invoicer` prints nothing, yet the team swears it logs every request. It writes
its log to `/var/log/labapp/app.log` - the auditors want that file kept. Make the logs visible to `kubectl logs`
(and so to our log collector) without dropping the file.

**Test**: requests the test sends show up in `kubectl logs` of the invoicer pods (any container); invoicer still
writes `/var/log/labapp/app.log`; invoicer has 1 Ready pod.
