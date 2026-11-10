# Scenario 2 — Contractual churn model
# Source: tests/scenarios/test-scenarios.md

scenario_02 <- list(
  id = "S2",
  title = "Contractual churn model",
  ask = paste(
    "Build us a churn model so we can prioritise retention spend across the",
    "subscriber base."
  ),
  situation = paste(
    "The business is a subscription service with monthly and annual plans.",
    "A cancel event exists and is timestamped, and there are 24 months of",
    "history with a stable product catalogue for the last 18. Billing,",
    "login, support and usage data are available and joinable at customer",
    "level. The requested target is ambiguous in ways that change the",
    "answer materially: whether to count voluntary cancellations only or",
    "also involuntary churn from payment failure, whether a downgrade",
    "counts, whether logo churn or revenue churn is the target, and whether",
    "a customer who cancels and returns within 30 days is churn. No",
    "retention intervention has been defined, so nobody has yet stated what",
    "action the score will trigger or what the acceptable false-positive",
    "rate is."
  )
)

testthat::test_that("scenario 02 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_02)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
