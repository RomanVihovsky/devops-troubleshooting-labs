# Solution - ship moved blocks inside the module

**Root cause**: v2.0.0 renamed `docker_volume.data` -> `docker_volume.this` and `docker_container.db`
-> `docker_container.this`. For every caller that is "destroy old address, create new" - with a database
volume in the middle.

**Fix (module author side, once for all 14 consumers)**
```hcl
moved {
  from = docker_volume.data
  to   = docker_volume.this
}
moved {
  from = docker_container.db
  to   = docker_container.this
}
```
commit, `git tag v2.0.1`, push; consumers bump to v2.0.1 -> plan shows two moves.

**Interview notes**
* Renaming resources in a published module is a breaking change unless it ships `moved` blocks.
  Keep them for at least one major version.
* `moved` inside a module uses addresses relative to the module - the caller's `module.db.` prefix is implied.
* Protect stateful resources in modules: `lifecycle { prevent_destroy = true }` on the volume would have
  turned this into a failed plan instead of a scary one.
* Test upgrades in the module's CI: apply vN, switch to vN+1, assert an empty plan - exactly what the
  lab's check did.
