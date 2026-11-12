# etl 1.6 crash-loops right after the start
**INC-2454** · P2 · Reporter: team analytics

We bumped `etl` to `labapp:1.6` (pushed last night from a developer laptop, the build server was down). Every
pod crash-loops at once, and the only log line is *exec /usr/local/bin/python3: exec format error*. 1.4 ran
fine. Get etl running again, on an image that matches our nodes.

**Test**: `etl` has 2 Ready pods, stable for 30 s, running a `registry.lab:5000/lab/labapp` image built for
`linux/amd64`.
