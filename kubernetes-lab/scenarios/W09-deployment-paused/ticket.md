# blog still runs 1.3
**INC-2496** · P3 · Reporter: team blog

An hour ago I ran `kubectl -n blog set image deploy/blog blog=registry.lab:5000/lab/labapp:1.4`. The Deployment
shows the new image, but all pods still run 1.3, and nothing is rolling. No errors anywhere.

**Test**: every `blog` pod runs `labapp:1.4` and is Ready (3 pods); the Deployment is not paused.
