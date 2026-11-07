terraform {
  required_version = ">= 1.10"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

module "db" {
  source   = "git::https://git.acme.example/platform/tf-module-pgbox.git?ref=v2.0.0"
  name     = "inventory"
  password = "lab-only-not-a-secret"
}
