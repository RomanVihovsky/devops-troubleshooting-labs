# L01 · First apply, fully offline
**Learn** · core workflow · ~15 min

Write your first configuration in `hello/` and walk the whole workflow once, the way a pipeline does.
Providers come from the lab's offline mirror (look at `$TF_CLI_CONFIG_FILE`) - nothing is downloaded.

1. Complete the TODOs in `hello/main.tf`: pin `hashicorp/random` and `hashicorp/local` with `~>`
   constraints, a `random_pet` called `name`, and a `local_file` called `greeting` that writes
   `Hello, <pet>!` to `hello/out/greeting.txt`.
2. `terraform init`, then open `.terraform.lock.hcl`: which versions were selected, and what are the hashes for?
3. `terraform plan -out=tfplan`, read it with `terraform show tfplan`, then `terraform apply tfplan`
   (a saved plan applies exactly what you reviewed - no second plan, no prompt).
4. `terraform plan -detailed-exitcode; echo $?` -> `0` = converged, `2` = changes pending, `1` = error.
5. The lock file is code: `git add hello/.terraform.lock.hcl && git commit -m "lock providers"`.

**Test**: providers pinned with `~>`; state holds `random_pet.name` and `local_file.greeting`;
`out/greeting.txt` greets the pet in state; the lock file is committed; a CI plan shows no changes.
