sed -i 's|config_path = "../../prod/network"|config_path = "../network"|' live/staging/app/terragrunt.hcl
tg_apply_all live/staging
