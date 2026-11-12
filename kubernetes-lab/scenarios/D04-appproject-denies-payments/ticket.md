# payments never deployed - Argo CD refuses
**INC-2252** · P2 · Reporter: team-a lead

Platform onboarded team-a yesterday: its own AppProject `team-a` and the first app `payments` (both in
`lab/gitops`, `apps/`). Argo CD shows `payments` with an error and nothing in the namespace `payments`.
Platform's rule: team-a gets exactly what it needs - no wildcards, no moving apps into another project.

**Test**: `payments` is Synced and Healthy and still in project `team-a`; team-a's project (in Git) lists
explicit destinations - no `*` - and still only this repo as source.
