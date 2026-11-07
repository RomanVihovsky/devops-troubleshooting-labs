terraform {
  required_version = ">= 1.10"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
  }
}

provider "docker" {}

provider "aws" {
  region = "eu-central-1"
}

variable "public_port" {
  type    = number
  default = 18090
}

variable "config_version" {
  type    = number
  default = 1
}

resource "docker_network" "shop" {
  name = "tfl-shop"

  ipam_config {
    subnet  = "10.79.20.0/24"
    gateway = "10.79.20.1"
  }

  labels {
    label = "terralab.scenario"
    value = "L07"
  }
}

data "docker_image" "nginx" {
  name = "nginx:1.27-alpine"
}

# Customer uploads. Losing this = restoring from backup.
resource "docker_volume" "data" {
  name = "tfl-shop-data"

  labels {
    label = "terralab.scenario"
    value = "L07"
  }

  # TODO 1: never destroy
}

resource "docker_container" "web" {
  name        = "tfl-shop-web"
  image       = data.docker_image.nginx.id
  memory      = 64
  memory_swap = 64

  networks_advanced {
    name = docker_network.shop.name
  }

  ports {
    internal = 80
    external = var.public_port
    ip       = "127.0.0.1"
  }

  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/srv/data"
  }

  labels {
    label = "terralab.scenario"
    value = "L07"
  }

  # TODO 3: replace when var.config_version changes
  # TODO 4: precondition - public_port in 18000-18999
}

# Marketing edits this in the console.
resource "aws_ssm_parameter" "banner" {
  name           = "/shop/banner"
  type           = "String"
  insecure_value = "Welcome!"

  # TODO 2: stop reverting marketing's edits
}

# TODO 5: check "web_up" - GET http://127.0.0.1:<public_port>/ must return 200
