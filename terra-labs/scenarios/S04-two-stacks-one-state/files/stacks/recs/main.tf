resource "aws_sns_topic" "updates" {
  name = "recs-model-updates"
}

resource "aws_ssm_parameter" "setting" {
  for_each = { model = "als-2026-10", threshold = "0.42" }

  name           = "/recs/${each.key}"
  type           = "String"
  insecure_value = each.value
}
