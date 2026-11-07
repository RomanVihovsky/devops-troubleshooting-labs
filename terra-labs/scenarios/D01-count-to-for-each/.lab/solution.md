# Solution - moved blocks for count -> for_each

**Root cause**: switching `count` to `for_each` changes every address from `web[0]` to `web["eu-1"]`.
Without instructions Terraform plans destroy-old + create-new for each instance.

**Fix**: one `moved` block per instance, mapping old index to new key (`git show HEAD~1` for the order):
```hcl
moved {
  from = docker_container.web[0]
  to   = docker_container.web["eu-1"]
}
# ... 5 more
```
Plan: 6 "has moved to", nothing else. Apply records it.

**Interview notes**
* `moved` (1.1+) is the reviewable, CI-friendly replacement for `terraform state mv`; it works across
  module boundaries and for count/for_each keys. Keep the blocks until all environments applied.
* `for` expressions cannot generate `moved` blocks - write them out (or generate the file with a script).
* Why `for_each`: identity by key. With `count`, deleting `sites[1]` shifts indices 2..5 -> 4 replacements.
