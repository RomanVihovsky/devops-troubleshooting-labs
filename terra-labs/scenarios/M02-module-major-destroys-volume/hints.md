## Hint 1
`git clone https://git.acme.example/platform/tf-module-pgbox.git /tmp/pgbox && git -C /tmp/pgbox diff v1.0.0 v2.0.0`.
What did "consistent naming" change, from Terraform's point of view?

## Hint 2
Resource addresses inside the module changed (`docker_volume.data` -> `docker_volume.this`, ...). A module
author can ship `moved` blocks **inside the module** - every caller's next plan then sees a move, not a
destroy. You could also add moved blocks in your stack, but then 13 teams must do the same.

## Hint 3
In the clone: add `moved` blocks to the module, commit, `git tag v2.0.1`, `git push origin main --tags`.
Then `?ref=v2.0.1` in `stacks/inventory-db`, `terraform init -upgrade`, plan: two moves, nothing else. Apply.
