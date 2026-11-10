# Scenario 6 — Per-customer price elasticity
# Source: tests/scenarios/test-scenarios.md

scenario_06 <- liminal_scenario_fixtures$S6

testthat::test_that("scenario 06 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_06)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
