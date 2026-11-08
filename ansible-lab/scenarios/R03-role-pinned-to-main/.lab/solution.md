# Solution - pin roles to tags

**Root cause**: `requirements.yml` pins `acme.banner` to `version: main`. The platform team pushed untagged 2.0
work to main; the next CI run installed it fresh, and 2.0's argument spec requires `banner_lines`.

**Fix**: `version: v1.2.0` (the deployed release). Upgrade deliberately: read the changelog, set
`banner_lines`, bump the pin in its own commit.

**Interview notes**
* Same for collections: `version: "==14.0.0"` (or a tarball/tag), never open ranges in production repos.
* Role argument specs (`meta/argument_specs.yml`) are validated before the role runs - a breaking change shows
  up as a clear error instead of a half-applied role.
* Renovate/Dependabot can bump pinned versions with a PR - pinning doesn't mean "never update".
