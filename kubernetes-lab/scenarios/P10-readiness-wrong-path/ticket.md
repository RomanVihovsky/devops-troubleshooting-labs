# quotes: pods Running, 0/1 Ready, nothing reachable
**INC-2410** · P2 · Reporter: quotes team

`quotes` (namespace `quotes`, `workspace/P10/quotes.yaml`) has all pods **Running** but **0/1 Ready**,
and calls to `http://quotes.quotes` time out. The image is the same as last week; only the probes were
"standardised".

**Test**: quotes is Ready, its Service has endpoints and answers 200 inside the cluster, and it still has a
readiness probe.
