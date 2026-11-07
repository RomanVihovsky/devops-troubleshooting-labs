cat >> stacks/analytics/exports.tf <<'TF'

# created by hand during the October outage - adopted
import {
  to = aws_s3_bucket.exports
  id = "acme-analytics-exports"
}
TF
apply stacks/analytics
