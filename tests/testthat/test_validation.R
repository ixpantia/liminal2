# Input validation for measure_liminal_space().

testthat::test_that("scores must be numeric", {
  testthat::expect_error(
    liminal2::measure_liminal_space(letters[1:7])
  )
})

testthat::test_that("scores must be named", {
  testthat::expect_error(
    liminal2::measure_liminal_space(unname(liminal_scores()))
  )
})

testthat::test_that("scores must have one value per dimension", {
  scores <- liminal_scores()

  testthat::expect_error(liminal2::measure_liminal_space(scores[-1]))
  testthat::expect_error(
    liminal2::measure_liminal_space(c(scores, extra = 0.5))
  )
})

testthat::test_that("score names must be unique and complete", {
  scores <- liminal_scores()

  duplicated <- scores
  names(duplicated)[2] <- names(duplicated)[1]
  testthat::expect_error(liminal2::measure_liminal_space(duplicated))

  renamed <- scores
  names(renamed)[1] <- "unknown_dimension"
  testthat::expect_error(liminal2::measure_liminal_space(renamed))
})

testthat::test_that("scores must be finite and inside the unit interval", {
  scores <- liminal_scores()

  na_scores <- scores
  na_scores[1] <- NA_real_
  testthat::expect_error(liminal2::measure_liminal_space(na_scores))

  nan_scores <- scores
  nan_scores[1] <- NaN
  testthat::expect_error(liminal2::measure_liminal_space(nan_scores))

  inf_scores <- scores
  inf_scores[1] <- Inf
  testthat::expect_error(liminal2::measure_liminal_space(inf_scores))

  low <- scores
  low[1] <- -0.1
  testthat::expect_error(liminal2::measure_liminal_space(low))

  high <- scores
  high[1] <- 1.1
  testthat::expect_error(liminal2::measure_liminal_space(high))
})

testthat::test_that("boundary scores are accepted", {
  testthat::expect_equal(
    liminal2::measure_liminal_space(liminal_scores(0)),
    1
  )
  testthat::expect_equal(
    liminal2::measure_liminal_space(liminal_scores(1)),
    0
  )
})

testthat::test_that("scenario lists must contain scores", {
  scenario <- liminal_scenario_fixtures$S1
  scenario$scores <- NULL

  testthat::expect_error(liminal2::measure_liminal_space(scenario))
  testthat::expect_error(liminal2::measure_liminal_space(list()))
  testthat::expect_error(liminal2::measure_liminal_space(NULL))
})
