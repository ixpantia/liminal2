# Scenario 3 — Credit risk scorecard
# Source: tests/scenarios/test-scenarios.md

scenario_03 <- liminal_scenario_fixtures$S3

testthat::test_that("scenario 03 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_03)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
