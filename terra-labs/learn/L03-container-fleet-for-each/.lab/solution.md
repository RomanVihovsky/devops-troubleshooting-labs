# Solution - L03

Reference: `.lab/solve.sh`. The core:
```hcl
resource "docker_container" "svc" {
  for_each    = var.services
  name        = "tfl-fleet-${each.key}"
  image       = data.docker_image.img[each.value.image].id
  memory      = each.value.memory
  memory_swap = each.value.memory
  networks_advanced { name = docker_network.fleet.name }
  ports { internal = 80  external = each.value.port  ip = "127.0.0.1" }
  dynamic "labels" {
    for_each = { "terralab.scenario" = "L03", service = each.key }
    content { label = labels.key  value = labels.value }
  }
}
output "endpoints" { value = { for k, s in var.services : k => "http://127.0.0.1:${s.port}" } }
```

**Takeaways**
* `for_each` keys are identities: `docker_container.svc["web"]`. Removing `api` touches only `api`.
  With `count`, removing an element in the middle renumbers everything after it -> replacements
  (converting is incident D01: `moved` blocks per index).
* Keys must be known at plan time - never key by computed IDs (incident C01).
* `dynamic` blocks generate nested blocks; use them for data-driven lists, not to hide simple config.
* Provider quirks are real: referencing the network by `.id`, or omitting `memory_swap`, makes this
  provider plan a change on every run (perpetual diff). A clean second plan is part of "done".
