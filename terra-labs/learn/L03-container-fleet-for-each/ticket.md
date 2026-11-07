# L03 · A container fleet with for_each
**Learn** · for_each, for expressions, dynamic blocks (docker provider) · ~20 min

`fleet/` should run one nginx container per entry of `var.services` (see `terraform.tfvars`)
on the lab's docker host. The network is there; the containers are not.

1. Write `docker_container` with `for_each = var.services`: name `tfl-fleet-<key>`, image from the
   given `data "docker_image"`, attached to the network **by name**, port 80 published on
   `127.0.0.1:<port>`, `memory` and `memory_swap` from the map.
2. Labels via a `dynamic "labels"` block over a map: `terralab.scenario = "L03"` and `service = <key>`.
3. `output "endpoints"`: a map `<key> => "http://127.0.0.1:<port>"` built with a `for` expression.
4. `terraform apply`, then `curl` the endpoints.
5. Retire `api`: delete it from `terraform.tfvars`. The plan must show **1 to destroy, nothing else**
   (that is the point of `for_each` over `count`). Apply.

**Test**: `tfl-fleet-web` and `tfl-fleet-static` run with their labels and memory limits and answer
on their ports; `tfl-fleet-api` is gone; `endpoints` lists exactly web and static; a CI plan shows no changes.
