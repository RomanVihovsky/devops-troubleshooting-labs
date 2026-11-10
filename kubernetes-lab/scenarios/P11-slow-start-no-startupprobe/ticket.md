# analytics restarts forever since the dataset grew
**INC-2411** · P2 · Reporter: analytics team

`analytics` (namespace `analytics`, `workspace/P11/analytics.yaml`) loads its dataset at start - now
**45 seconds** (it was 5). Since then the pods restart again and again and never become Ready. Don't
weaken the liveness check for normal operation: it caught real hangs before.

**Test**: analytics is Ready with no new restarts for 60 s; the liveness probe is unchanged (period 5 s,
failureThreshold 3, initialDelaySeconds 10).
