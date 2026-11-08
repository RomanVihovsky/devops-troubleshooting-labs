# Solution - tags on include_role don't reach the role's tasks

**Root cause**: `include_role` is dynamic. Its `tags: [deploy]` select the *include* itself; the tasks it loads
have no tags, so `--tags deploy` filters every one of them out. The job is green with `changed=0`.

**Fix**: `apply: {tags: [deploy]}` on the include (keeps it dynamic), or `import_role` (static: tags and
`when` are copied to every task).

**Interview notes**
* import_* = static, resolved at parse time: tags/when inherited, `--list-tasks` shows the tasks, no loops.
* include_* = dynamic, resolved at run time: loops and variable names possible, keywords apply to the include
  only unless passed via `apply`.
* `when` on `include_role` is evaluated once; on `import_role` it is evaluated per task (can matter if a task
  changes the condition).
* Always test tag-based jobs with `--list-tasks` in CI.
