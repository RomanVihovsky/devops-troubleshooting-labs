mock_provider "aws" {}

run "page_size_is_a_string" {
  command = plan

  variables {
    page_size = 25
  }

  assert {
    condition     = aws_ssm_parameter.page_size.insecure_value == "25"
    error_message = "page size not rendered"
  }
}
