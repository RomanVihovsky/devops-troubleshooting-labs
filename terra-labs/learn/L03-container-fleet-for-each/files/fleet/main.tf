terraform {
  required_version = ">= 1.10"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

provider "docker" {}

variable "services" {
  type = map(object({
    image  = string
    port   = number
    memory = optional(number, 64) # MiB
  }))
}

# Lab docker host rules: names start with tfl-, label terralab.scenario, memory_swap = memory.
resource "docker_network" "fleet" {
  name = "tfl-fleet"

  ipam_config {
    subnet  = "10.79.10.0/24"
    gateway = "10.79.10.1"
  }

  labels {
    label = "terralab.scenario"
    value = "L03"
  }
}

# Local images only (nothing is pulled). One lookup per distinct image.
data "docker_image" "img" {
  for_each = toset([for s in var.services : s.image])
  name     = each.key
}

# TODO: resource "docker_container" "svc" - one per entry of var.services (see the task)

# TODO: output "endpoints"
