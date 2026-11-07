resource "aws_sns_topic" "orders" {
  name = "orders-events"
}

resource "aws_ssm_parameter" "orders_topic" {
  name           = "/notifications/orders-topic-arn"
  type           = "String"
  insecure_value = aws_sns_topic.orders.arn
}
