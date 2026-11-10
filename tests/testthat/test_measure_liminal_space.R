# Core behaviour of measure_liminal_space().

testthat::test_that("perfect clarity yields zero liminality", {
  result <- liminal2::measure_liminal_space(liminal_scores(1))

  testthat::expect_equal(result, 0)
})

testthat::test_that("total ambiguity yields liminality of one", {
  result <- liminal2::measure_liminal_space(liminal_scores(0))

  testthat::expect_equal(result, 1)
})

testthat::test_that("equal scores reproduce the score value", {
  result <- liminal2::measure_liminal_space(liminal_scores(0.5))

  testthat::expect_equal(result, 0.5)
})

testthat::test_that("a single zero score drives liminality to one", {
  scores <- liminal_scores(0.8)
  scores[["shared_meaning"]] <- 0

  result <- liminal2::measure_liminal_space(scores)

  testthat::expect_equal(result, 1)
})

testthat::test_that("weighted geometric mean matches the formula", {
  scores <- liminal_varying_scores()
  weights <- liminal_weights()
  weights[["shared_meaning"]] <- 0.4
  weights[-1] <- 0.1

  expected <- 1 - prod(scores^weights)

  testthat::expect_equal(
    liminal2::measure_liminal_space(scores, weights),
    expected
  )
})

testthat::test_that("liminality stays within the unit interval", {
  results <- vapply(
    liminal_scenario_fixtures,
    liminal2::measure_liminal_space,
    numeric(1)
  )

  testthat::expect_true(all(results >= 0))
  testthat::expect_true(all(results <= 1))
})

testthat::test_that("measurement is deterministic", {
  scores <- liminal_scores(0.6)

  testthat::expect_identical(
    liminal2::measure_liminal_space(scores),
    liminal2::measure_liminal_space(scores)
  )
})

testthat::test_that("score order does not affect the result", {
  scores <- liminal_scores(0.6)
  reordered <- scores[rev(liminal_dimension_names)]

  testthat::expect_equal(
    liminal2::measure_liminal_space(scores),
    liminal2::measure_liminal_space(reordered)
  )
})

testthat::test_that("raising a score cannot raise liminality", {
  base <- liminal_scores(0.6)
  raised <- base
  raised[["judgeable"]] <- 0.8

  testthat::expect_lte(
    liminal2::measure_liminal_space(raised),
    liminal2::measure_liminal_space(base)
  )
})

testthat::test_that("scenario lists and score vectors agree", {
  scenario <- liminal_scenario_fixtures$S1

  testthat::expect_equal(
    liminal2::measure_liminal_space(scenario),
    liminal2::measure_liminal_space(scenario$scores)
  )
})
