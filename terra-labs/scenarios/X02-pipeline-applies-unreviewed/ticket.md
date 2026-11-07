# Postmortem action: the pipeline applied a change nobody reviewed
**PM-77** · P2 · Reporter: postmortem review

Timeline: 10:02 MR A planned (`ci/pipeline.sh plan`), reviewer approved the plan at 11:30. Meanwhile at
10:45 MR B was merged to the same branch. The approved apply job ran at 11:31 - and applied **A and B**.
B had never been reviewed and took the catalog down.

Fix the pipeline so `apply` can only ever do what was reviewed.

**Test**: after `plan`, a newer commit landing before `apply` is **not** applied (the reviewed change is);
`apply` without a reviewed plan fails instead of applying whatever the code says now.
