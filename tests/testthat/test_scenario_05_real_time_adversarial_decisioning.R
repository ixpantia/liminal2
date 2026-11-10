# Scenario 5 — Real-time adversarial decisioning
# Source: tests/scenarios/test-scenarios.md

scenario_05 <- liminal_scenario_fixtures$S5

testthat::test_that("scenario 05 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_05)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
