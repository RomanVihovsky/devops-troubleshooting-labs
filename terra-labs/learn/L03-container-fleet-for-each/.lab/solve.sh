python3 - <<'PY'
p = "fleet/main.tf"
s = open(p).read()
s = s.replace('''# TODO: resource "docker_container" "svc" - one per entry of var.services (see the task)

# TODO: output "endpoints"''', '''resource "docker_container" "svc" {
  for_each = var.services

  name        = "tfl-fleet-${each.key}"
  image       = data.docker_image.img[each.value.image].id
  memory      = each.value.memory
  memory_swap = each.value.memory

  networks_advanced {
    name = docker_network.fleet.name
  }

  ports {
    internal = 80
    external = each.value.port
    ip       = "127.0.0.1"
  }

  dynamic "labels" {
    for_each = {
      "terralab.scenario" = "L03"
      service             = each.key
    }
    content {
      label = labels.key
      value = labels.value
    }
  }
}

output "endpoints" {
  value = { for k, s in var.services : k => "http://127.0.0.1:${s.port}" }
}''')
open(p, "w").write(s)
PY
apply fleet
python3 - <<'PY'
p = "fleet/terraform.tfvars"
s = open(p).read()
s = s.replace('''  api = {
    image = "nginx:1.27-alpine"
    port  = 18082
  }
''', "")
open(p, "w").write(s)
PY
apply fleet
