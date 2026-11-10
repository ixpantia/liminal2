# Scenario 1 — Execution indicators
# Source: tests/scenarios/test-scenarios.md

scenario_01 <- list(
  id = "S1",
  title = "Execution indicators",
  ask = paste(
    "Give us indicators of project execution built from the data we already",
    "have: number of tasks opened and closed, and hours assigned by person",
    "and by project. We want to know which projects are running well."
  ),
  situation = paste(
    "Task and timesheet data are complete, in-house, and mature, covering",
    "roughly three years with stable definitions. Project codes are",
    "consistent, hours are booked against tasks rather than projects, and",
    "closures are timestamped. The business has not stated what it means by",
    "\"execution,\" what decisions the indicator drives, or who acts when a",
    "project is flagged, and there is no agreed baseline for what normal",
    "looks like."
  )
)

testthat::test_that("scenario 01 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_01)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
