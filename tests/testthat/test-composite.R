test_that("composite endpoints are correct", {
  all_one <- setNames(rep(1, 6), paste0("a", 1:6))
  all_zero <- setNames(rep(0, 6), paste0("a", 1:6))
  expect_equal(liminality(all_one)$A, 1)
  expect_equal(liminality(all_one)$L, 0)
  expect_equal(liminality(all_zero)$A, 0)
  expect_equal(liminality(all_zero)$L, 1)
})

test_that("geometric and arithmetic formulas match", {
  a <- c(
    a1 = 0.9, a2 = 0.8, a3 = 0.7,
    a4 = 0.6, a5 = 0.5, a6 = 0.4
  )
  w <- default_weights()
  geometric <- prod(a^w)
  arithmetic <- sum(w * a)
  expect_equal(liminality(a)$A, geometric)
  expect_equal(liminality(a, method = "arithmetic")$A, arithmetic)
  both <- liminality(a, method = "both")
  expect_equal(both$A, geometric)
  expect_equal(both$A_arithmetic, arithmetic)
})

test_that("dimensions and dominance are reported", {
  a <- c(
    a1 = 0.9, a2 = 0.9, a3 = 0.9,
    a4 = 0.9, a5 = 0.1, a6 = 0.1
  )
  result <- liminality(a)
  expect_equal(unname(result$dimensions[["L3"]]), 0.9)
  expect_equal(result$dominant_dimension, "L3")
  expect_true(result$unbounded)
})

test_that("bad components and weights error", {
  a <- c(
    a1 = 0.9, a2 = 0.8, a3 = 0.7,
    a4 = 0.6, a5 = 0.5, a6 = 0.4
  )
  expect_error(liminality(unname(a)), "named")
  expect_error(liminality(a * 1.2), "\\[0, 1\\]")
  expect_error(
    liminality(a, w = unname(default_weights())),
    "names"
  )
  expect_error(
    liminality(a, w = default_weights() * 2),
    "sum to 1"
  )
})

test_that("assess_goal accepts precomputed components", {
  a <- c(
    a1 = 0.9, a2 = 0.8, a3 = 0.7,
    a4 = 0.6, a5 = 0.5, a6 = 0.4
  )
  result <- assess_goal(a = a, method = "both")
  expect_s3_class(result, "liminality_assessment")
  expect_equal(result$components, a)
  expect_error(
    assess_goal(a = a, n_boot = 5),
    "raw component inputs"
  )
})

test_that("S3 methods work", {
  a <- c(
    a1 = 0.9, a2 = 0.8, a3 = 0.7,
    a4 = 0.6, a5 = 0.5, a6 = 0.4
  )
  result <- liminality(a)
  output <- capture.output(print(result))
  expect_true(any(grepl("adjudication strength", output)))
  summary_result <- summary(result)
  expect_s3_class(summary_result, "summary.liminality_assessment")
  expect_silent(capture.output(print(summary_result)))
  frame <- as.data.frame(result)
  expect_equal(nrow(frame), 1L)
  expect_true(all(c("A", "L", "a1", "L3") %in% names(frame)))
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_silent(plot(result))
})

test_that("bootstrap works when raw inputs are available", {
  set.seed(1)
  n <- 160L
  X <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  y <- as.integer(X$x + stats::rnorm(n) > 0)
  defs <- data.frame(
    first = y,
    second = ifelse(stats::runif(n) < 0.1, 1 - y, y)
  )
  oracle <- c(
    external_authority = 1, codified_definition = 1,
    timeliness = 0.75, model_independence = 1,
    inter_judge_agreement = 0.75, ex_post_detectability = 1
  )
  normative <- c(
    threshold_owner = 0.75, cost_ratio_agreed = 0.5,
    stakeholder_agreement = 0.75, regulatory_constraint = 0.5,
    reversibility = 0.75, precedent = 0.5
  )
  goal <- assess_goal(
    label_defs = defs,
    X = X,
    time_index = seq_len(n),
    y = y,
    oracle_scores = oracle,
    normative_scores = normative,
    component_args = list(
      a3 = list(variant = "subsample", B = 8),
      a4 = list(folds = 3, repeats = 1)
    ),
    seed = 42
  )
  expect_s3_class(goal, "liminality_assessment")
  boot <- bootstrap_liminality(goal, B = 10, seed = 7)
  expect_s3_class(boot, "liminality_bootstrap")
  expect_true(all(c("A", "L") %in% rownames(boot$ci)))
  expect_silent(capture.output(print(boot)))
})

test_that("weight sensitivity is deterministic and ranks two goals", {
  first <- c(
    a1 = 0.9, a2 = 0.8, a3 = 0.7,
    a4 = 0.6, a5 = 0.5, a6 = 0.4
  )
  second <- first - 0.05
  first_result <- weight_sensitivity(
    list(first, second),
    n = 200, seed = 11
  )
  second_result <- weight_sensitivity(
    list(first, second),
    n = 200, seed = 11
  )
  expect_s3_class(first_result, "liminality_sensitivity")
  expect_identical(first_result$L_draws, second_result$L_draws)
  expect_gte(first_result$ranking_fraction, 0)
  expect_lte(first_result$ranking_fraction, 1)
  expect_silent(capture.output(print(first_result)))
})
