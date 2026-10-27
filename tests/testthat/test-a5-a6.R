test_that("oracle and normative rubrics load", {
  oracle <- read_rubric("oracle")
  normative <- read_rubric("normative")
  expect_equal(oracle$name, "oracle")
  expect_equal(normative$name, "normative")
  expect_length(oracle$item_names, 6)
  expect_length(normative$item_names, 6)
  expect_equal(sum(oracle$weights), 1)
  expect_equal(sum(normative$weights), 1)
})

test_that("rubric scores are anchored weighted means", {
  scores <- c(
    external_authority = 1,
    codified_definition = 1,
    timeliness = 1,
    model_independence = 1,
    inter_judge_agreement = 1,
    ex_post_detectability = 1
  )
  value <- rubric_score(scores, "oracle")
  expect_equal(as.numeric(value), 1)

  scores[["timeliness"]] <- 0.5
  value <- rubric_score(scores, "oracle")
  expect_equal(as.numeric(value), 1 - 0.5 / 6)
})

test_that("custom rubric weights are rescaled", {
  scores <- c(
    external_authority = 1,
    codified_definition = 0,
    timeliness = 0,
    model_independence = 0,
    inter_judge_agreement = 0,
    ex_post_detectability = 0
  )
  weights <- c(
    external_authority = 2,
    codified_definition = 0,
    timeliness = 0,
    model_independence = 0,
    inter_judge_agreement = 0,
    ex_post_detectability = 0
  )
  value <- rubric_score(scores, "oracle", weights = weights)
  expect_equal(as.numeric(value), 1)
})

test_that("invalid scores and rubrics error", {
  scores <- c(
    external_authority = 0.3,
    codified_definition = 1,
    timeliness = 1,
    model_independence = 1,
    inter_judge_agreement = 1,
    ex_post_detectability = 1
  )
  expect_error(rubric_score(scores, "oracle"), "0.25")
  expect_error(
    rubric_score(setNames(rep(1, 6), c("a", "b", "c", "d", "e", "f"))),
    "exactly these items"
  )
})

test_that("malformed rubric YAML errors", {
  path <- tempfile(fileext = ".yml")
  writeLines("name: broken\nitems:\n  - [unclosed", path)
  expect_error(read_rubric(path), "Malformed|items")
})
