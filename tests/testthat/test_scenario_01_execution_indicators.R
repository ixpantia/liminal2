# Scenario 1 — Execution indicators
# Source: tests/scenarios/test-scenarios.md

scenario_01 <- liminal_scenario_fixtures$S1

testthat::test_that("scenario 01 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_01)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
