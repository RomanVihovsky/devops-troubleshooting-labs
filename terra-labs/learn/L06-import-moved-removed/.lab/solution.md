# Solution - L06

Reference: `.lab/solve.sh` (it keeps the generated `generated.tf` as is; in a real PR you would
tidy it: drop defaults, use `jsonencode()` for the policy, move it into `main.tf`).

```hcl
locals { flags = { checkout = "on", search = "off", recs = "on" } }

import {
  for_each = local.flags
  to       = aws_ssm_parameter.flag[each.key]
  id       = "/legacy/flags/${each.key}"
}
resource "aws_ssm_parameter" "flag" {
  for_each       = local.flags
  name     = "/legacy/flags/${each.key}"
  type     = "String"
  value    = each.value   # import reads the value into `value`
}

import {
  to = aws_iam_role.reporting
  id = "legacy-reporting"
}                           # + terraform plan -generate-config-out=generated.tf

removed {
  from = aws_s3_bucket.reports
  lifecycle { destroy = false }
}
```

**Takeaways**
* `import` blocks (1.5+) are plannable, reviewable and repeatable - unlike `terraform import`.
  `for_each` on import (1.7+); since 1.16 import blocks may live **inside modules**.
* `-generate-config-out` only works for imports without `for_each`, and generates everything the
  provider reads back - always edit the result.
* `removed { lifecycle { destroy = false } }` (1.7+) = reviewed `terraform state rm`. With
  `destroy = true` (default) it is a reviewed delete. The receiving team imports it on their side.
* Importing with config that differs from what the provider reads back is "import + update" in the
  same apply. Here: `insecure_value = "on"` looks identical, but import fills `value`, so Terraform
  would rewrite all three parameters (version 2). Always read the plan for `~` on imported resources.
