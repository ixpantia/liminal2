# Weight behaviour for measure_liminal_space().

testthat::test_that("default weights are equal and sum to one", {
  weights <- liminal2::default_weights()

  testthat::expect_length(weights, length(liminal_dimension_names))
  testthat::expect_identical(names(weights), liminal_dimension_names)
  testthat::expect_true(all(weights >= 0))
  testthat::expect_equal(sum(weights), 1)
  testthat::expect_equal(
    unname(weights),
    rep(
      1 / length(liminal_dimension_names),
      length(liminal_dimension_names)
    )
  )
})

testthat::test_that("custom weights change the measured value", {
  scores <- liminal_varying_scores()
  weights <- liminal_weights()
  weights[["shared_meaning"]] <- 0.7
  weights[-1] <- 0.05

  testthat::expect_false(isTRUE(all.equal(
    liminal2::measure_liminal_space(scores, weights),
    liminal2::measure_liminal_space(scores)
  )))
})

testthat::test_that("zero-weight dimensions do not affect the result", {
  weights <- liminal_weights()
  weights[["shared_meaning"]] <- 0
  weights[["stable_ground"]] <- 2 / 7

  low <- liminal_varying_scores()
  low[["shared_meaning"]] <- 0
  high <- liminal_varying_scores()
  high[["shared_meaning"]] <- 1

  testthat::expect_equal(
    liminal2::measure_liminal_space(low, weights),
    liminal2::measure_liminal_space(high, weights)
  )
})

testthat::test_that("weight order does not affect the result", {
  scores <- liminal_varying_scores()
  weights <- liminal_weights()
  reversed <- rev(liminal_dimension_names)

  testthat::expect_equal(
    liminal2::measure_liminal_space(scores, weights),
    liminal2::measure_liminal_space(scores[reversed], weights[reversed])
  )
})

testthat::test_that("invalid weights are rejected", {
  scores <- liminal_varying_scores()
  weights <- liminal_weights()

  negative <- weights
  negative[1] <- -0.1
  testthat::expect_error(liminal2::measure_liminal_space(scores, negative))

  short <- weights[-1]
  testthat::expect_error(liminal2::measure_liminal_space(scores, short))

  unnamed <- unname(weights)
  testthat::expect_error(liminal2::measure_liminal_space(scores, unnamed))

  renamed <- weights
  names(renamed)[1] <- "unknown_dimension"
  testthat::expect_error(liminal2::measure_liminal_space(scores, renamed))

  bad_sum <- weights * 2
  testthat::expect_error(liminal2::measure_liminal_space(scores, bad_sum))

  non_finite <- weights
  non_finite[1] <- NA_real_
  testthat::expect_error(
    liminal2::measure_liminal_space(scores, non_finite)
  )

  non_numeric <- as.character(weights)
  testthat::expect_error(
    liminal2::measure_liminal_space(scores, non_numeric)
  )
})
