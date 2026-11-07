terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 4.0"
    }
  }
}

variable "name" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

data "docker_image" "postgres" {
  name = "postgres:16-alpine"
}

resource "docker_volume" "data" {
  name = "tfl-${var.name}-pgdata"

  labels {
    label = "terralab.scenario"
    value = "M02"
  }
}

resource "docker_container" "db" {
  name        = "tfl-${var.name}-db"
  image       = data.docker_image.postgres.id
  memory      = 256
  memory_swap = 256
  env         = ["POSTGRES_PASSWORD=${var.password}"]

  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/var/lib/postgresql/data"
  }

  labels {
    label = "terralab.scenario"
    value = "M02"
  }
}

output "container" {
  value = docker_container.db.name
}
