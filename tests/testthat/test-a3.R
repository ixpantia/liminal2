test_that("identical candidate models give multiplicity one", {
  set.seed(1)
  X <- data.frame(x = stats::rnorm(300))
  y <- as.integer(X$x > 0)
  constant <- function(X_train, y_train, X_new) {
    rep(0.5, nrow(X_new))
  }
  value <- predictive_multiplicity(
    X, y,
    fit_predict = constant,
    variant = "subsample",
    B = 10,
    seed = 42
  )
  expect_equal(as.numeric(value), 1)
})

test_that("balanced disagreement gives multiplicity about one half", {
  set.seed(2)
  n <- 400L
  X <- data.frame(x = stats::rnorm(n))
  y <- rep(c(0L, 1L), length.out = n)
  disagree <- function(X_train, y_train, X_new) {
    if (X_train$x[1L] > 0) {
      rep(0, nrow(X_new))
    } else {
      rep(1, nrow(X_new))
    }
  }
  value <- predictive_multiplicity(
    X, y,
    fit_predict = disagree,
    variant = "subsample",
    B = 500,
    eps = 0.1,
    seed = 42
  )
  expect_lt(abs(as.numeric(value) - 0.5), 0.12)
})

test_that("multiplicity is deterministic under a fixed seed", {
  set.seed(3)
  X <- data.frame(
    a = stats::rnorm(400),
    b = stats::rnorm(400)
  )
  y <- as.integer(X$a + 0.3 * stats::rnorm(400) > 0)
  first <- predictive_multiplicity(
    X, y,
    variant = "subsample", B = 20, seed = 5
  )
  second <- predictive_multiplicity(
    X, y,
    variant = "subsample", B = 20, seed = 5
  )
  expect_identical(first, second)
})

test_that("larger epsilon cannot decrease multiplicity", {
  set.seed(4)
  X <- data.frame(
    a = stats::rnorm(600),
    b = stats::rnorm(600)
  )
  y <- as.integer(X$a + 0.2 * stats::rnorm(600) > 0)
  narrow <- predictive_multiplicity(
    X, y,
    variant = "subsample", B = 50, eps = 0.01, seed = 9
  )
  wide <- predictive_multiplicity(
    X, y,
    variant = "subsample", B = 50, eps = 0.2, seed = 9
  )
  expect_gte(as.numeric(narrow) + 0.05, as.numeric(wide))
})

test_that("multiplicity restores the random-number state", {
  set.seed(5)
  X <- data.frame(x = stats::rnorm(200))
  y <- as.integer(X$x > 0)
  before <- .Random.seed
  predictive_multiplicity(
    X, y,
    variant = "subsample", B = 10, seed = 7
  )
  expect_identical(before, .Random.seed)
})
