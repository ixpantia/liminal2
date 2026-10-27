simulate_auc_data <- function(auc, n = 4000L, seed = 1L) {
  set.seed(seed)
  predictor <- stats::rnorm(n)
  scale <- .scale_for_auc(auc)
  y <- as.integer(scale * predictor + stats::rnorm(n) > 0)
  list(X = data.frame(predictor = predictor), y = y)
}

test_that("known Bayes AUC values are recovered", {
  for (auc in c(0.6, 0.7, 0.8, 0.9)) {
    data <- simulate_auc_data(auc, seed = round(auc * 100))
    value <- discriminability(
      data$X, data$y,
      folds = 5, repeats = 3, seed = 42
    )
    expected <- 2 * auc - 1
    expect_lt(abs(as.numeric(value) - expected), 0.07)
  }
})

test_that("random labels give near-zero discriminability", {
  set.seed(10)
  X <- data.frame(predictor = stats::rnorm(1000))
  y <- sample(c(0L, 1L), 1000, replace = TRUE)
  value <- suppressWarnings(
    discriminability(X, y, folds = 5, repeats = 3, seed = 42)
  )
  expect_lte(as.numeric(value), 0.1)
})

test_that("leakage raises discriminability and is flagged", {
  set.seed(11)
  X <- data.frame(predictor = stats::rnorm(800))
  y <- as.integer(X$predictor > 0)
  X$leak <- y + stats::rnorm(800, sd = 0.01)
  value <- discriminability(X, y, folds = 5, repeats = 2, seed = 42)
  expect_gt(as.numeric(value), 0.9)
  audit <- audit_leakage(
    X, y,
    permutations = 5, repeats = 2, seed = 42
  )
  expect_true(audit$flagged)
})

test_that("discriminability restores the random-number state", {
  set.seed(12)
  X <- data.frame(predictor = stats::rnorm(300))
  y <- as.integer(X$predictor > 0)
  before <- .Random.seed
  discriminability(X, y, folds = 3, repeats = 1, seed = 7)
  expect_identical(before, .Random.seed)
})
