# L01 - your first configuration. Fill in the TODOs, then follow the steps of the task.

terraform {
  required_version = ">= 1.10"

  required_providers {
    # TODO: hashicorp/random and hashicorp/local, each pinned with a "~>" constraint
  }
}

# TODO: resource "random_pet" "name" - two words joined with "-"

# TODO: resource "local_file" "greeting" - writes "Hello, <pet>!" to out/greeting.txt next to this file

# TODO: output "greeting_file" - the path of the file
