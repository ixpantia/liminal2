test_that("no drift gives stability one", {
  X <- data.frame(value = rep(1, 400))
  value <- temporal_stability(X, time_index = seq_len(400), k = 4)
  expect_equal(as.numeric(value), 1)
})

test_that("a known categorical PSI maps to the expected score lambda", {
  n <- 4000L
  time <- seq_len(n)
  split <- floor(n / 2)
  first <- rep(c("a", "b"), length.out = split)
  second <- c(
    rep("a", floor(0.26 * split)),
    rep("b", split - floor(0.26 * split))
  )
  X <- data.frame(value = factor(c(first, second)))
  value <- temporal_stability(X, time_index = time, k = 2)
  expect_equal(as.numeric(value), 0.5, tolerance = 0.02)
})

test_that("stability decreases monotonically with drift", {
  set.seed(2)
  n <- 2000L
  base <- stats::rnorm(n)
  time <- seq_len(n)
  X0 <- data.frame(value = base)
  X1 <- data.frame(value = base + 0.4 * time / n)
  X2 <- data.frame(value = base + 1.2 * time / n)
  value0 <- temporal_stability(X0, time, k = 4)
  value1 <- temporal_stability(X1, time, k = 4)
  value2 <- temporal_stability(X2, time, k = 4)
  expect_gt(value0, value1)
  expect_gt(value1, value2)
})

test_that("empty bins do not produce non-finite scores", {
  X <- data.frame(
    value = c(rep(0, 100), rep(100, 100))
  )
  value <- temporal_stability(X, seq_len(200), k = 4)
  expect_true(is.finite(value))
  expect_true(value > 0 && value <= 1)
  drift <- attr(value, "feature_drift")
  expect_true(all(is.finite(drift)))
})

test_that("alternative drift statistics work", {
  set.seed(3)
  X <- data.frame(value = stats::rnorm(500))
  time <- seq_len(500)
  expect_true(is.finite(temporal_stability(X, time, type = "ks")))
  expect_true(is.finite(temporal_stability(X, time, type = "chisq")))
})

test_that("invalid temporal inputs error", {
  X <- data.frame(value = 1:10)
  expect_error(
    temporal_stability(X, time_index = seq_len(9)),
    "one value per row"
  )
  expect_error(
    temporal_stability(X, time_index = rep(1, 10), k = 2),
    "unique time"
  )
})
