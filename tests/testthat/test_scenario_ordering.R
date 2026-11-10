# Integration: liminality must increase along the scenario ladder.

testthat::test_that("scenario liminality increases along the ladder", {
  measures <- vapply(
    liminal_scenario_fixtures,
    liminal2::measure_liminal_space,
    numeric(1)
  )

  testthat::expect_identical(
    names(measures),
    names(liminal_scenario_fixtures)
  )
  testthat::expect_true(all(is.finite(measures)))
  testthat::expect_true(all(measures > 0))
  testthat::expect_true(all(measures <= 1))
  testthat::expect_true(all(diff(measures) > 0))
  testthat::expect_identical(
    unname(which.max(measures)),
    length(measures)
  )
})

testthat::test_that("scenario measurement is reproducible", {
  first <- vapply(
    liminal_scenario_fixtures,
    liminal2::measure_liminal_space,
    numeric(1)
  )
  second <- vapply(
    liminal_scenario_fixtures,
    liminal2::measure_liminal_space,
    numeric(1)
  )

  testthat::expect_identical(first, second)
})
