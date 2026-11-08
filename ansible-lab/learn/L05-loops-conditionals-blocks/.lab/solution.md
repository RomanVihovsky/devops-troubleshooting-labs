# Solution - L05

Reference: `.lab/solve.sh`.

**Takeaways**
* `loop` + `loop_control.label` (readable output - and it keeps secrets out of logs, see S02).
* Booleans only in `when` since 2.19: `item.admin` is a real bool; strings need `| bool`.
* `rescue` runs only if a task in the block failed; the play continues and the host counts as `rescued`.
  `always` runs either way - ordering still matters (the directory had to exist before the rescue wrote into it).
* Read-only commands: `changed_when: false` (and `check_mode: false` if later tasks need their output - E03).
