sed -i 's|source = "../../../modules/app"|source = "../../../modules//app"|' live/dev/checkout/terragrunt.hcl
tg_apply_all live/dev
