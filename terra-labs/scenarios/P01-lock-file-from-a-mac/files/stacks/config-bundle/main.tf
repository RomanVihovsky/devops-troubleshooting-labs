terraform {
  required_version = ">= 1.10"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "random_id" "bundle" {
  byte_length = 4
}

resource "local_file" "manifest" {
  filename = "${path.module}/out/manifest.json"
  content  = jsonencode({ bundle = random_id.bundle.hex, services = ["cart", "search"] })
}
