# Banner deploy fails since this morning: "missing required arguments: banner_lines"
**OPS-290** · P2 · Reporter: CI

Nobody committed to our repo since last week (`git log`), yet `ci/pipeline.sh` fails today:
```
Validating arguments against arg spec 'main' ... missing required arguments: banner_lines
```
The platform team says the banner role's next major version is "work in progress on main".

**Test**: `ci/pipeline.sh` (fresh role install) passes and converges against what is deployed; the role is pinned
to a released tag; the banners on web1/web2 are unchanged.
