# Last night's scale-up hotfix (4 replicas) vanished overnight
**INC-902 follow-up** · P1 · Reporter: SRE on-call

During INC-902 I scaled web to 4 replicas: I edited `live/prod/.terragrunt-stack/web/terragrunt.values.hcl`
and ran `terragrunt apply` right there. It worked. The nightly `terragrunt stack run -- apply` put it
back to 2 and the incident came back at 06:00.

Make 4 replicas the real configuration.

**Test**: `/prod/web/replicas` is 4; a fresh CI checkout's `terragrunt stack run -- plan` shows no
changes; `.terragrunt-stack/` is not committed.
