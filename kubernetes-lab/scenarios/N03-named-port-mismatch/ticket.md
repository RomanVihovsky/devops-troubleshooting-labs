# maps Service broken after the port rename
**INC-2603** · P2 · Reporter: maps team

We renamed the container port of `maps` from `http` to `web` (house style) in `workspace/N03/maps.yaml`
(namespace `maps`). Pods are Ready, but `http://maps.maps` doesn't work any more. The port name `web` stays.

**Test**: `http://maps.maps/` answers 200 inside the cluster; the container port is still named `web`.
