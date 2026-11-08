# CI runner
Playbooks run inside the execution environment named in `ci/ee-image` (`./lab ee run "$(cat ci/ee-image)" ...`).
Released image tags are **immutable**: runners cache them (pull policy `missing`). New definition -> new tag.
Build: `ansible-builder create` in `ee/` (with `ee/wheels` = the wheelhouse), then `./lab ee build ee <tag>`.
