cat > hello/main.tf <<'TF'
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

resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

resource "local_file" "greeting" {
  filename = "${path.module}/out/greeting.txt"
  content  = "Hello, ${random_pet.name.id}!\n"
}

output "greeting_file" {
  value = local_file.greeting.filename
}
TF
run_logged "$SETUP_LOG" tf hello init -input=false -no-color
run_logged "$SETUP_LOG" tf hello plan -out=tfplan -input=false -no-color
run_logged "$SETUP_LOG" tf hello apply -input=false -no-color tfplan
git add hello/.terraform.lock.hcl hello/main.tf
git commit -q -m "hello: first apply, lock providers"
