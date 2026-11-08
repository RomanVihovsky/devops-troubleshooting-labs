# Flapping check: EDA restarted nginx on web1 23 times in 10 minutes
**PM-212** · P2 · Reporter: incident commander (postmortem action item)

Tuesday 02:10-02:20 the nginx check on **web1** flapped (monitoring's probe timed out under load). Monitoring
re-sends a `down` alert every 15 s while a check is failing, and every single one reached the EDA activation:
it restarted nginx on web1 **23 times**, the last ones 6 minutes after the check had recovered (the activation
works through its alerts one by one). Each restart dropped all open connections - the self-healing made a 2-minute
blip a 16-minute outage.

Action item: the self-healing may restart nginx **at most once per host in 10 minutes**. The first alert must still
be handled right away, and an alert for a *different* host inside that window must be handled too. Monitoring's
re-send behaviour stays as it is.

**Test**: the activation runs from a CI checkout; with nginx stopped on web1 and web3, a burst of 8 `down` alerts
for web1 and 2 for web3 heals both within 60 s with **exactly one** nginx start on each (journal); site.yml converges.
