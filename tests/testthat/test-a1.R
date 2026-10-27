test_that("perfect agreement gives alpha one", {
  defs <- data.frame(
    first = rep(c("yes", "no"), 50),
    second = rep(c("yes", "no"), 50)
  )
  value <- label_determinacy(defs, n_boot = 0)
  expect_equal(as.numeric(value), 1)
})

test_that("random labels give alpha near zero", {
  set.seed(42)
  y <- sample(c("yes", "no"), 3000, replace = TRUE)
  defs <- data.frame(
    first = y,
    second = sample(y),
    third = sample(y)
  )
  value <- suppressWarnings(
    label_determinacy(defs, method = "krippendorff", n_boot = 0)
  )
  expect_lt(unname(value), 0.05)
  expect_gte(unname(value), 0)
})

test_that("missing labels are allowed", {
  defs <- data.frame(
    first = c("a", "b", "c", "a", NA),
    second = c("a", "b", "c", NA, "a"),
    third = c("a", "b", NA, "a", "a")
  )
  value <- label_determinacy(defs, n_boot = 0)
  expect_true(is.finite(value))
  expect_true(value >= 0 && value <= 1)
})

test_that("fleiss and confident learning are bounded", {
  defs <- data.frame(
    first = c("a", "b", "a", "b", "a"),
    second = c("a", "b", "b", "b", "a"),
    third = c("a", "b", "a", "b", "b")
  )
  fleiss <- label_determinacy(defs, method = "fleiss", n_boot = 0)
  confident <- label_determinacy(
    defs,
    method = "confident_learning", n_boot = 0
  )
  hybrid <- label_determinacy(defs, method = "hybrid", n_boot = 0)
  expect_true(all(c(fleiss, confident, hybrid) >= 0))
  expect_true(all(c(fleiss, confident, hybrid) <= 1))
  expect_lte(unname(hybrid), unname(confident) + 1e-12)
})

test_that("bootstrap interval and RNG restoration work", {
  defs <- data.frame(
    first = rep(c("a", "b"), 100),
    second = rep(c("a", "b"), 100)
  )
  set.seed(99)
  before <- .Random.seed
  value <- label_determinacy(defs, n_boot = 20, seed = 11)
  after <- .Random.seed
  expect_identical(before, after)
  expect_equal(length(attr(value, "ci")), 2L)
})

test_that("invalid determinacy inputs error", {
  expect_error(
    label_determinacy(data.frame(a = 1:3), n_boot = 0),
    "two definitions"
  )
  expect_error(
    label_determinacy(
      data.frame(a = rep("x", 3), b = rep("x", 3)),
      n_boot = 0
    ),
    "one category"
  )
})

test_that("Krippendorff agrees with irr for two coders", {
  skip_if_not_installed("irr")
  set.seed(7)
  coders <- matrix(
    sample(1:3, size = 80, replace = TRUE),
    nrow = 2,
    ncol = 40
  )
  our <- .kripp_alpha_nominal(as.data.frame(t(coders)))
  reference <- irr::kripp.alpha(coders, method = "nominal")$value
  expect_equal(our, reference, tolerance = 1e-8)
})
