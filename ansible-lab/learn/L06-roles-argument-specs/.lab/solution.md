# Solution - L06

Reference: `.lab/solve.sh`.

**Takeaways**
* `meta/argument_specs.yml` = typed role interface, validated before the role's tasks run (also documents the
  role for `ansible-doc -t role`). 2.22 adds `no_log` support for options.
* Defaults for knobs, `vars/` for facts of life (paths per OS) - never put user-tunable values in `vars/` (V01).
* `first_found` + `os_family` (then `distribution`, then `distribution_major_version` for finer files) beats a
  forest of `when:`s.
* Prefix every role variable with the role name - variables are play-global (incident V04).
