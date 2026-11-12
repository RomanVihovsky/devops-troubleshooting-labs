# No export for two nights
**INC-2493** · P2 · Reporter: data team

The `export` CronJob (namespace `cron`) produced nothing for two nights. Its schedule is right. For this test
it runs every minute (`*/1 * * * *`); keep that schedule and keep `concurrencyPolicy: Forbid` (two exports at
once corrupt the target). On Monday someone "paused it while investigating a hang".

**Test**: a Job created by the `export` CronJob **after** this incident started has completed successfully;
the CronJob is not suspended, its schedule and `concurrencyPolicy: Forbid` unchanged; no export run hangs.
