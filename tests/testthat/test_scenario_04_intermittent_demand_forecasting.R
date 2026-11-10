# Scenario 4 — Intermittent demand forecasting
# Source: tests/scenarios/test-scenarios.md

scenario_04 <- list(
  id = "S4",
  title = "Intermittent demand forecasting",
  ask = paste(
    "Predict tomorrow's purchases for each of our 1,800 SKUs across 50,000",
    "customers."
  ),
  situation = paste(
    "Roughly 90 million customer-SKU-day cells, of which the overwhelming",
    "majority are zero. Most SKUs sell irregularly, with gaps longer than a",
    "week, and a meaningful share sell fewer than ten times a year in",
    "total. Historical sales are available for three years but are",
    "censored by stockouts, which were not recorded, so zero sales and zero",
    "demand are indistinguishable. Promotions, assortment changes and price",
    "changes are documented unevenly. Two large ambiguities remain",
    "unresolved: the intended use — replenishment, assortment decisions, or",
    "campaign targeting — and therefore the loss function, since a",
    "replenishment use penalises under-forecast asymmetry while a targeting",
    "use needs calibrated probabilities. The business has asked for daily",
    "granularity for all combinations, including customers with fewer than",
    "five purchase events."
  )
)

testthat::test_that("scenario 04 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_04)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
