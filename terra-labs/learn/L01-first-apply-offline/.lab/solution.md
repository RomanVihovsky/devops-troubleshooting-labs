# Solution - L01

```hcl
terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.7" }
    local  = { source = "hashicorp/local",  version = "~> 2.5" }
  }
}
resource "random_pet" "name" { length = 2  separator = "-" }
resource "local_file" "greeting" {
  filename = "${path.module}/out/greeting.txt"
  content  = "Hello, ${random_pet.name.id}!\n"
}
```

**Takeaways**
* `~> 3.7` = ">= 3.7, < 4.0": minor/patch updates allowed, majors are a deliberate change.
* `.terraform.lock.hcl` pins the exact versions + package hashes **per platform**. Commit it.
  From an offline mirror you only get the `h1:` hash of your own platform - add others with
  `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64` (incident P01).
* `plan -out` + `apply <planfile>` is the review-then-apply contract of every good pipeline;
  `-detailed-exitcode` is how scripts tell "no changes" (0) from "changes" (2) from "error" (1).
* Local state (`terraform.tfstate`) is fine for this, never for a team: next up, L04.
