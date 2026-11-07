# The nightly apply reverted ops' 3 a.m. hotfix - and will tonight again
**INC-889 follow-up** · P1 · Reporter: SRE on-call

During INC-889 ops changed two things on the orders database by hand (console, 03:12):
* SSM `/orders/db/max-connections` from `100` to `400`;
* a new ingress rule on security group `orders-db`: port 5432 from the reporting network `10.30.0.0/16`.

Last night's scheduled apply of `stacks/orders-db` put max-connections back to 100 - the incident
re-opened until ops re-applied the hotfix this morning. It runs again tonight.

Make the hotfix permanent **in code**. Nothing may be recreated, and the hotfix rule must be managed
by Terraform from now on (with a description).

**Test**: max-connections is 400 and the reporting rule exists; the rule is in Terraform state;
the security group is the same one; a CI plan shows no changes.
