## Hint 1
`terraform providers` lists every constraint per module. Who wants what? Then
`git clone https://git.acme.example/platform/tf-module-topic.git /tmp/m && git -C /tmp/m log --oneline --decorate`
and read `CHANGELOG.md`.

## Hint 2
Terraform needs ONE provider version satisfying **all** constraints in the tree. `~> 5.0` (module)
and `~> 6.0` (root) have no overlap. Loosening the root is off the table - which module version fits?

## Hint 3
Use `?ref=v2.0.0` and follow its upgrade note (`name` -> `topic_name`). `terraform init -upgrade`
(new module version), plan: in-place updates only (encryption), no replacement. Apply.
