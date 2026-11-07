# Solution - a third unit owns the relationship

**Root cause**: network -> app (needs the app SG ID for the db rule) and app -> network (needs the VPC
ID). Terragrunt's DAG can't order two units that need each other's outputs.

**Fix**: move the relationship into its own unit `db-access` (module `db-access`) that depends on both;
network no longer depends on app. Order: network -> app -> db-access.

**Interview notes**
* Same shape as the Terraform-level cycle (C02): resolve by extracting the edge into a separate
  resource/unit.
* `terragrunt dag graph` / `terragrunt list --dag` show the order; a cycle error names the units.
* Unit boundaries = blast radius + lifecycle. "Security rules between tiers" is a good candidate for its
  own unit (changes often, owned by security).
