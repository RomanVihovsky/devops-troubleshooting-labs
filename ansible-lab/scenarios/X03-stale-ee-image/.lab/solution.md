# Solution - a changed EE definition needs a new image and a new tag

**Root cause**: jmespath was added to `ee/execution-environment.yml`, but nobody built an image from it. CI still
runs `acme/ee:1` - built before the change. The controller works because jmespath is installed there: "works on
my laptop" in its purest form.

**Fix**: `ansible-builder create` + build -> `acme/ee:2`; point `ci/ee-image` at it; leave `:1` alone.

**Interview notes**
* Treat EEs like any artifact: definition in git, CI builds on change, immutable tags (semver or git SHA),
  consumers pin the tag (navigator `execution-environment.image`, AAP job templates).
* Rebuilding a tag in place breaks reproducibility and caches (`pull: policy: missing`).
* `ansible-navigator images` / `ansible-builder introspect` show what's inside an EE.
* The controller and the EE must not drift: develop *in* the EE (`ansible-navigator run --ee true`).
