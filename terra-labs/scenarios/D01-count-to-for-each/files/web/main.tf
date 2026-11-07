terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

variable "sites" {
  type    = list(string)
  default = ["eu-1", "eu-2", "us-1", "us-2", "ap-1", "ap-2"]
}

data "docker_image" "nginx" {
  name = "nginx:1.27-alpine"
}

resource "docker_container" "web" {
  for_each = toset(var.sites)

  name        = "tfl-web-${each.key}"
  image       = data.docker_image.nginx.id
  memory      = 32
  memory_swap = 32

  labels {
    label = "terralab.scenario"
    value = "D01"
  }
}
