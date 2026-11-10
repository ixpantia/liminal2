# Scenario 2 — Contractual churn model
# Source: tests/scenarios/test-scenarios.md

scenario_02 <- liminal_scenario_fixtures$S2

testthat::test_that("scenario 02 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_02)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
