run "rounds_half_up" {
  command = plan
  variables {
    net_cents = 999
  }
  assert {
    condition     = output.gross_cents == 1189 # 1188.81
    error_message = "got ${output.gross_cents}"
  }
}

run "discount_before_vat" {
  command = plan
  variables {
    net_cents        = 1000
    discount_percent = 10
  }
  assert {
    condition     = output.gross_cents == 1071
    error_message = "got ${output.gross_cents}"
  }
}

run "no_rounding_needed" {
  command = plan
  variables {
    net_cents   = 2000
    vat_percent = 7
  }
  assert {
    condition     = output.gross_cents == 2140
    error_message = "got ${output.gross_cents}"
  }
}

run "rejects_huge_discount" {
  command = plan
  variables {
    net_cents        = 1000
    discount_percent = 80
  }
  expect_failures = [var.discount_percent]
}
