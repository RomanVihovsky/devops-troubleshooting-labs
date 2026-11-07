# Solution - a reference, not a string

**Root cause**: `networks_advanced { name = "tfl-jobs-net" }` is a literal. Terraform sees no
relationship between the containers and `docker_network.jobs` and creates them in parallel (default
parallelism 10). If a container is created first, Docker can't find the network.

**Fix**: `name = docker_network.jobs.name` - same value, plus an implicit dependency.

**Interview notes**
* Implicit dependencies (references) > `depends_on` (explicit, coarse, makes data sources read late).
* Hard-coded names/ARNs/IDs instead of references are the classic source of ordering races and of
  "works the second time". `terraform graph` (or `-format=mermaid` in 1.16+) shows the truth.
* `-parallelism=1` would hide the bug, not fix it.
