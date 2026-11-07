# Solution - the tests were right

**Root cause**: the "simplification" changed behaviour in three ways: `floor()` without `+ 0.5`
(truncation instead of commercial rounding), the discount subtracted as cents *after* VAT instead of a
percentage *before* VAT, and the validation was dropped. The tests caught all three.

**Fix**: restore the semantics in the code (here: the previous version - the refactor added nothing but a
shorter expression). Tests unchanged.

**Interview notes**
* "Update the expected values" is how bugs get certified. A failing test is a question: is the code
  wrong or the requirement changed? Here finance owns the requirement.
* Pure-logic modules (naming, pricing, CIDR math) are cheap to cover with `command = plan` tests -
  no infrastructure needed.
* Protect test files with CODEOWNERS so behaviour changes need the owner's review.
