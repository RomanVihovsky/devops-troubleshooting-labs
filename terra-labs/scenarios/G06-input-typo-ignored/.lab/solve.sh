sed -i 's/  replica_count = local.env_cfg.replicas/  replicas = local.env_cfg.replicas/' live/staging/web/terragrunt.hcl
tg_apply_all live/staging
