# DR region bootstrap fails: "Invalid for_each argument"
**INFRA-201** · P2 · Reporter: platform (DR project)

`stacks/logs` runs fine in prod. Bootstrapping the new `dr` environment with the same code fails at plan:
`Invalid for_each argument ... the "for_each" map includes keys derived from resource attributes that
cannot be determined until apply`. Someone suggests `-target` the buckets first, then apply the rest.

Make the code work for a brand-new environment **without** `-target` - and prod must not see a single
change: replacing a public access block opens a window without public-access protection.

Environments: `env/<env>.s3.tfbackend` + `env/<env>.tfvars` (`terraform init -reconfigure -backend-config=...`).

**Test**: `dr` is applied (3 log buckets, each with a public access block); CI plans of both `prod` and `dr`
show no changes; prod's buckets and access blocks were not replaced.
