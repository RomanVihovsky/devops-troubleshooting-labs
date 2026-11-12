# quotes is slow, but its CPU is "idle"
**INC-2523** · P2 · Reporter: team quotes

`quotes` (`workspace/R03/quotes.yaml`) has a p99 of seconds under a modest load, and our dashboard shows its
pods at ~5% of a node's CPU. Nothing else on those nodes is busy. Each request hashes a session token (that's the
CPU part, and it stays). The platform team's "resource limits for everyone" change landed last week.

**Test**: under the test's load (2 pods, 20 requests/s for 20 s) p99 < 200 ms with no errors; the CPU limit is at
least 500m or removed; the pods still have a CPU request.
