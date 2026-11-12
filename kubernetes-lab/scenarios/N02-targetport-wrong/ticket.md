# weather API: connection refused through the Service
**INC-2601** · P2 · Reporter: weather team

`http://weather.weather` gives **connection refused**, but `curl <pod IP>:8080` from another pod works.
The manifests are in `workspace/N02/weather.yaml` (namespace `weather`).

**Test**: `http://weather.weather/` answers 200 inside the cluster; the app still listens on 8080.
