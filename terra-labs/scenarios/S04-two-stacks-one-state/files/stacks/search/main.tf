resource "aws_sns_topic" "updates" {
  name = "search-index-updates"
}

resource "aws_ssm_parameter" "setting" {
  for_each = { index = "products-v7", replicas = "3" }

  name           = "/search/${each.key}"
  type           = "String"
  insecure_value = each.value
}
