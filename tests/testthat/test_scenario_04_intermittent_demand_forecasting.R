# Scenario 4 — Intermittent demand forecasting
# Source: tests/scenarios/test-scenarios.md

scenario_04 <- liminal_scenario_fixtures$S4

testthat::test_that("scenario 04 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_04)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
