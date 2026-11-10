# Scenario 3 — Credit risk scorecard
# Source: tests/scenarios/test-scenarios.md

scenario_03 <- list(
  id = "S3",
  title = "Credit risk scorecard",
  ask = paste(
    "Build a credit scoring model for our lending portfolio so we can",
    "approve, price and set limits."
  ),
  situation = paste(
    "A regulated lender with 60 months of disbursement and performance",
    "history, bureau data at application, and complete repayment records.",
    "Default is externally defined: 90 days past due, consistent with",
    "regulatory practice, so the label itself is not in question. Volumes",
    "are adequate but approval volumes were historically constrained by a",
    "manual policy, so the observed portfolio is a selected sample. Two",
    "decisions remain genuinely undefined: the performance horizon for the",
    "score (12 versus 24 months changes the label population), and the use",
    "of the output — approve/decline only, or approve/decline plus pricing",
    "and limit assignment, each requiring different calibration and",
    "different cut-off analysis. The business also expects a single score",
    "to serve both new applicants and existing-customer limit management,",
    "which are different populations with different available features."
  )
)

testthat::test_that("scenario 03 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_03)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
