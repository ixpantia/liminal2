# Scenario 6 — Per-customer price elasticity
# Source: tests/scenarios/test-scenarios.md

scenario_06 <- list(
  id = "S6",
  title = "Per-customer price elasticity",
  ask = paste(
    "Tell us the price elasticity of each of our 400,000 customers so we",
    "can set individual prices before next quarter."
  ),
  situation = paste(
    "A 12% price increase was applied to the entire customer base in all",
    "regions on the same date, eight months ago. No phased rollout, no",
    "holdout, no comparison market. Prices were uniform for the preceding",
    "five years, so there is no historical price variation. Sales,",
    "transaction and margin data are complete and readily available. The",
    "business has stated it cannot run an experiment and needs the answer",
    "in two weeks."
  )
)

testthat::test_that("scenario 06 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_06)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
