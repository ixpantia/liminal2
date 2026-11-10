# Scenario 5 — Real-time adversarial decisioning
# Source: tests/scenarios/test-scenarios.md

scenario_05 <- list(
  id = "S5",
  title = "Real-time adversarial decisioning",
  ask = paste(
    "Score every transaction in the payment path and block fraud before",
    "authorisation."
  ),
  situation = paste(
    "A payments environment with a 200 ms end-to-end budget including",
    "network and fallback. The confirmed-fraud rate is under 0.5%, and",
    "labels arrive 60 to 120 days later through chargebacks and",
    "investigation outcomes. The three fraud types in scope — stolen",
    "instrument, account takeover, and first-party abuse — have different",
    "costs and different label paths, and the business has not supplied a",
    "cost matrix or a review-capacity constraint, so the trade-off between",
    "a false decline and an unreviewed fraud case is currently undefined.",
    "Analyst review capacity is fixed at roughly 400 cases per day, which",
    "silently imposes the real operating threshold. Critically, the model's",
    "own blocks remove cases from the observed population, so labels are",
    "missing not at random."
  )
)

testthat::test_that("scenario 05 yields a non-zero liminal space", {
  result <- liminal2::measure_liminal_space(scenario_05)

  testthat::expect_true(is.numeric(result))
  testthat::expect_length(result, 1L)
  testthat::expect_true(is.finite(result))
  testthat::expect_gt(result, 0)
})
