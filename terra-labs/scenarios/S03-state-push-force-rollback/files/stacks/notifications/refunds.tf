resource "aws_sns_topic" "refunds" {
  name = "refunds-events"
}

resource "aws_ssm_parameter" "refunds_topic" {
  name           = "/notifications/refunds-topic-arn"
  type           = "String"
  insecure_value = aws_sns_topic.refunds.arn
}

resource "aws_iam_role" "notifier" {
  name = "notifier"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}
