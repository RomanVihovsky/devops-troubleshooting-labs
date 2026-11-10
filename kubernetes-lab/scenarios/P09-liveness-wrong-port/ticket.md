# profile service restarts all day, logs look fine
**INC-2409** · P3 · Reporter: profile team

`profile` (namespace `profile`, `workspace/P09/profile.yaml`) serves requests fine, then restarts - about
every 30 seconds, restart counter climbing. The logs show no error before the restart. We added health
checks last sprint ("best practice").

**Test**: profile is Ready with no new restarts for 60 s, and it still has a liveness probe.
