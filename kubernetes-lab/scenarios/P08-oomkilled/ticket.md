# search-cache restarts every few minutes
**INC-2408** · P2 · Reporter: search team

`search-cache` (namespace `search-cache`, `workspace/P08/cache.yaml`) restarts constantly; `kubectl
describe` says **OOMKilled**, exit code 137. We need the 192 MB cache (`CACHE_MB`), that's the whole point
of the service.

**Test**: search-cache is Ready with no new restarts for 60 s; `CACHE_MB` is still 192.
