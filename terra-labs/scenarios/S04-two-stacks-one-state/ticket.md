# Two pipelines keep deleting each other's resources
**INFRA-140** · P1 · Reporter: search & recommendations teams

Since the recommendations team bootstrapped `stacks/recs` (copied from `stacks/search` last week),
every run of one pipeline **destroys the other team's resources**. Right now the search parameters
and topic exist (search applied last) and recs has nothing. Both teams are blaming Terraform.

Make both stacks live side by side. Search must not be touched again - its topic has subscribers.

**Test**: CI plans of both stacks show no changes; the search topic is the one that exists now (not
recreated); the recs parameters and topic exist; the two stacks have separate states.
