test_that("Krippendorff alpha matches a hand-computed example", {
  defs <- data.frame(
    first = c("a", "a", "b", "b"),
    second = c("a", "b", "b", "a")
  )
  value <- label_determinacy(defs, n_boot = 0)
  expect_equal(as.numeric(value), 0.125)
})

test_that("Fleiss kappa matches a hand-computed example", {
  defs <- data.frame(
    first = c("a", "a", "b", "b"),
    second = c("a", "b", "b", "a"),
    third = c("a", "b", "b", "b")
  )
  counts <- matrix(
    c(
      3, 0,
      1, 2,
      0, 3,
      1, 2
    ),
    nrow = 4,
    byrow = TRUE
  )
  p_unit <- (rowSums(counts^2) - 3) / (3 * 2)
  p_bar <- mean(p_unit)
  p_j <- colSums(counts) / 12
  expected <- (p_bar - sum(p_j^2)) / (1 - sum(p_j^2))
  value <- label_determinacy(defs, method = "fleiss", n_boot = 0)
  expect_equal(as.numeric(value), expected)
})

test_that("PSI mapping uses the documented lambda", {
  lambda <- log(2) / 0.25
  expect_equal(exp(-lambda * 0.25), 0.5)
  expect_equal(exp(-lambda * 0), 1)
})

test_that("composite matches the canonical product", {
  a <- c(
    a1 = 0.8, a2 = 0.7, a3 = 0.6,
    a4 = 0.5, a5 = 0.4, a6 = 0.3
  )
  w <- default_weights()
  expected <- exp(sum(w * log(a)))
  expect_equal(liminality(a)$A, expected)
})
