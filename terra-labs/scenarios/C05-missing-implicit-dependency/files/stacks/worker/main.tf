terraform {
  required_version = ">= 1.10"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

data "docker_image" "worker" {
  name = "alpine:3.20"
}

resource "docker_network" "jobs" {
  name = "tfl-jobs-net"

  ipam_config {
    subnet  = "10.79.40.0/24"
    gateway = "10.79.40.1"
  }

  labels {
    label = "terralab.scenario"
    value = "C05"
  }
}

resource "docker_container" "worker" {
  for_each = toset(["mail", "pdf", "thumbs"])

  name        = "tfl-worker-${each.key}"
  image       = data.docker_image.worker.id
  command     = ["sleep", "infinity"]
  memory      = 16
  memory_swap = 16

  networks_advanced {
    name = "tfl-jobs-net"
  }

  labels {
    label = "terralab.scenario"
    value = "C05"
  }
}
