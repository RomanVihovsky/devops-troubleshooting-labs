# Solution - L12

Reference: `.lab/solve.sh` (the EE definition and the three commands).

**Takeaways**
* An EE = base image + ansible-core + ansible-runner + collections + Python and system dependencies, described
  in `execution-environment.yml` (v3) and built by `ansible-builder` (`create` = Containerfile context, `build` =
  create + container build).
* `ansible-navigator run site.yml --ee true --eei acme/ee:1` does what `./lab ee run` does: start the image
  with your project mounted (arbitrary UID, group 0, HOME=/runner). AAP/AWX run jobs the same way.
* Pin everything in the EE (base image digest, ansible-core, collections) and version the image; the playbook
  repo then states which EE it needs.
* Missing Python libraries show up as filter/module errors only *inside* the EE - incident X03.
