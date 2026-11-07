# Solution - review and apply the same saved plan

**Root cause**: `apply` re-planned from whatever code was checked out at apply time (`apply -auto-approve`).
The reviewed `plan.txt` was just text; B slipped in between review and apply.

**Fix**
```bash
plan)  terraform plan -out="$ART/tfplan"; terraform show -no-color "$ART/tfplan" > "$ART/plan.txt" ;;
apply) [ -f "$ART/tfplan" ] || exit 1; terraform apply "$ART/tfplan" ;;
```

**Interview notes**
* A saved plan pins the exact changes and the state serial it was made against: if anything changed
  the state since, apply fails with "Saved plan is stale" - re-plan and re-review.
* Plan files contain sensitive values - treat the artifact like a secret (short retention, restricted).
* Same with Terragrunt: `run --all -- plan -out=tfplan` then `run --all -- apply tfplan` (`--out-dir`
  collects them), and Atlantis/Spacelift/HCP implement exactly this.
* Merge queues / "apply before merge" avoid the race differently.
