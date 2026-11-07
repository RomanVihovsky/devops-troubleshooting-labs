## Hint 1
Inside a `for_each` resource you have `each.key` ("web") and `each.value` (its object):
`name = "tfl-fleet-${each.key}"`, `image = data.docker_image.img[each.value.image].id`,
`memory = each.value.memory`.

## Hint 2
```
networks_advanced { name = docker_network.fleet.name }
ports { internal = 80  external = each.value.port  ip = "127.0.0.1" }
dynamic "labels" {
  for_each = { "terralab.scenario" = "L03", service = each.key }
  content { label = labels.key  value = labels.value }
}
```

## Hint 3
`output "endpoints" { value = { for k, s in var.services : k => "http://127.0.0.1:${s.port}" } }`.
After removing `api`, `terraform plan` should say `Plan: 0 to add, 0 to change, 1 to destroy.`
With `count` the containers after the removed one would shift index and be replaced.
