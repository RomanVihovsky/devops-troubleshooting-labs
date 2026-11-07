## Hint 1
`terraform test -verbose` - which runs fail and by how much? `git show HEAD -- modules/pricing` shows what
the refactor changed.

## Hint 2
Off by one cent here and there, or discount applied in the wrong place? Compare the old and new
expressions with `terraform console` (`floor(1188.81)`, `floor(1188.81 + 0.5)`).

## Hint 3
Restore the behaviour the tests describe (commercial rounding, discount before VAT, the validation) -
in the code. Keep the parts of the refactor that don't change behaviour.
