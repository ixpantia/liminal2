test_that("all exported component estimators return unit scalars", {
  set.seed(1)
  X <- data.frame(
    x = stats::rnorm(300),
    z = stats::rnorm(300)
  )
  y <- as.integer(X$x > 0)
  defs <- data.frame(first = y, second = y)
  values <- c(
    a1 = label_determinacy(defs, n_boot = 0),
    a2 = temporal_stability(X, seq_len(300), k = 3),
    a3 = predictive_multiplicity(
      X, y,
      variant = "subsample", B = 10, seed = 1
    ),
    a4 = discriminability(X, y, folds = 3, repeats = 1, seed = 1),
    a5 = rubric_score(
      c(
        external_authority = 1, codified_definition = 1,
        timeliness = 1, model_independence = 1,
        inter_judge_agreement = 1, ex_post_detectability = 1
      ),
      "oracle"
    ),
    a6 = rubric_score(
      c(
        threshold_owner = 1, cost_ratio_agreed = 1,
        stakeholder_agreement = 1, regulatory_constraint = 1,
        reversibility = 1, precedent = 1
      ),
      "normative"
    )
  )
  expect_true(all(is.finite(values)))
  expect_true(all(values >= 0 & values <= 1))
})

test_that("weights must be named and sum to one", {
  a <- setNames(rep(0.5, 6), paste0("a", 1:6))
  expect_error(liminality(a, w = rep(1 / 6, 6)), "names")
  expect_error(
    liminality(a, w = setNames(rep(0.1, 6), paste0("a", 1:6))),
    "sum to 1"
  )
  expect_error(
    liminality(a, w = setNames(rep(1 / 6, 6), letters[1:6])),
    "named exactly"
  )
})

test_that("component values are validated rather than clipped", {
  a <- c(
    a1 = 1.1, a2 = 0.8, a3 = 0.7,
    a4 = 0.6, a5 = 0.5, a6 = 0.4
  )
  expect_error(liminality(a), "\\[0, 1\\]")
  expect_error(liminality(a - 2), "\\[0, 1\\]")
})

test_that("data digests are deterministic and input sensitive", {
  first <- .data_digest(list(a = 1:10))
  second <- .data_digest(list(a = 1:10))
  third <- .data_digest(list(a = 1:11))
  expect_identical(first, second)
  expect_false(identical(first, third))
})

test_that("stochastic functions restore the caller RNG state", {
  set.seed(99)
  before <- .Random.seed
  weight_sensitivity(
    setNames(rep(0.5, 6), paste0("a", 1:6)),
    n = 20, seed = 3
  )
  expect_identical(before, .Random.seed)
})
