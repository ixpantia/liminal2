test_that("leakage audit flags a label-derived feature", {
  set.seed(21)
  X <- data.frame(predictor = stats::rnorm(600))
  y <- as.integer(X$predictor + stats::rnorm(600) > 0)
  clean <- audit_leakage(
    X, y,
    permutations = 5, repeats = 2, seed = 42
  )
  expect_false(clean$flagged)

  X$leak <- y + stats::rnorm(600, sd = 0.01)
  leaked <- audit_leakage(
    X, y,
    permutations = 5, repeats = 2, seed = 42
  )
  expect_true(leaked$flagged)
  expect_gt(leaked$a4, 0.9)
  expect_silent(capture.output(print(leaked)))
})

test_that("construct validity reports a correlation", {
  x <- c(0.05, 0.12, 0.31, 0.48, 0.77)
  external <- c(1, 2, 3, 4, 6)
  result <- validate_index(x, external, method = "spearman")
  expect_s3_class(result, "liminality_validity")
  expect_equal(result$n, 5L)
  expect_true(result$estimate > 0.9)
  expect_silent(capture.output(print(result)))
})
