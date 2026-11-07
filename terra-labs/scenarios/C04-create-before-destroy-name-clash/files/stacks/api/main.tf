terraform {
  required_version = ">= 1.10"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

variable "color" {
  type = string
}

data "docker_image" "nginx" {
  name = "nginx:1.27-alpine"
}

resource "docker_network" "api" {
  name = "tfl-api-net"

  ipam_config {
    subnet  = "10.79.30.0/24"
    gateway = "10.79.30.1"
  }

  labels {
    label = "terralab.scenario"
    value = "C04"
  }
}

resource "docker_container" "api" {
  name        = "tfl-api"
  image       = data.docker_image.nginx.id
  memory      = 32
  memory_swap = 32
  env         = ["APP_COLOR=${var.color}"]

  networks_advanced {
    name    = docker_network.api.name
    aliases = ["api"]
  }

  labels {
    label = "terralab.scenario"
    value = "C04"
  }

  labels {
    label = "app"
    value = "api"
  }

  # zero downtime: start the new one before removing the old one
  lifecycle {
    create_before_destroy = true
  }
}
