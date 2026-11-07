cat > stacks/legacy/main.tf <<'TF'
locals {
  flags = {
    checkout = "on"
    search   = "off"
    recs     = "on"
  }
}

import {
  for_each = local.flags
  to       = aws_ssm_parameter.flag[each.key]
  id       = "/legacy/flags/${each.key}"
}

resource "aws_ssm_parameter" "flag" {
  for_each = local.flags

  name  = "/legacy/flags/${each.key}"
  type  = "String"
  value = each.value # what import reads back (insecure_value would plan an update)
}

import {
  to = aws_iam_role.reporting
  id = "legacy-reporting"
}

removed {
  from = aws_s3_bucket.reports
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3_bucket_versioning.reports
  lifecycle {
    destroy = false
  }
}
TF
run_logged "$SETUP_LOG" tf stacks/legacy init -input=false -no-color
run_logged "$SETUP_LOG" tf stacks/legacy plan -input=false -no-color -generate-config-out=generated.tf
apply stacks/legacy
