# Behaviour of assess_liminal_space() with an injected fake chat.
#
# The fake chat implements only $chat_structured(), which is the
# sequential path; the concurrent path is exercised by the opt-in
# integration tests.

fake_chat <- function(scores) {
  counter <- new.env(parent = emptyenv())
  counter$i <- 0L
  list(
    chat_structured = function(prompt, type, ...) {
      counter$i <- counter$i + 1L
      list(score = scores[[counter$i]])
    }
  )
}

failing_chat <- function(fail_until = Inf) {
  counter <- new.env(parent = emptyenv())
  counter$i <- 0L
  list(
    chat_structured = function(prompt, type, ...) {
      counter$i <- counter$i + 1L
      if (counter$i <= fail_until) {
        stop("simulated transport failure")
      }
      list(score = 3L)
    }
  )
}

testthat::test_that("assess_liminal_space returns a complete assessment", {
  raw <- c(3L, 2L, 5L, 4L, 6L, 7L, 8L)
  names(raw) <- liminal_dimension_names

  assessment <- liminal2::assess_liminal_space(
    ask = "Build us a churn model.",
    chat = fake_chat(raw),
    parallel = FALSE
  )

  testthat::expect_s3_class(assessment, "liminal_assessment")
  testthat::expect_identical(assessment$raw_scores, raw)
  testthat::expect_equal(assessment$scores, 1 - raw / 10)
  testthat::expect_identical(names(assessment$scores), liminal_dimension_names)
  testthat::expect_equal(
    assessment$liminality,
    liminal2::measure_liminal_space(assessment$scores)
  )
  testthat::expect_identical(
    names(assessment$weights),
    liminal_dimension_names
  )
  testthat::expect_true(all(assessment$prompt_versions == "1.1.0"))
  testthat::expect_identical(
    names(assessment$prompt_versions),
    liminal_dimension_names
  )
  testthat::expect_equal(assessment$ask, "Build us a churn model.")
  testthat::expect_null(assessment$situation)
  testthat::expect_true(is.na(assessment$model))
  testthat::expect_true(is.na(assessment$base_url))
})

testthat::test_that("the assessment prints", {
  assessment <- liminal2::assess_liminal_space(
    ask = "Build us a churn model.",
    chat = fake_chat(rep(3L, 7L)),
    parallel = FALSE
  )

  testthat::expect_output(
    print(assessment),
    "Liminal space assessment"
  )
  testthat::expect_output(print(assessment), "shared_meaning: 3")
})

testthat::test_that("raw scores convert to the condition scale", {
  convert <- liminal2:::convert_scores

  testthat::expect_equal(
    convert(c(shared_meaning = 0)),
    c(shared_meaning = 1)
  )
  testthat::expect_equal(
    convert(c(shared_meaning = 10)),
    c(shared_meaning = 0)
  )
  testthat::expect_equal(
    convert(c(shared_meaning = 5)),
    c(shared_meaning = 0.5)
  )

  raw <- seq(0, 10)
  testthat::expect_true(all(diff(convert(raw)) < 0))
  testthat::expect_true(all(convert(raw) >= 0))
  testthat::expect_true(all(convert(raw) <= 1))
})

testthat::test_that("invalid model output fails fast", {
  for (bad in list(-1, 11, 2.5, "7", NULL, c(1, 2))) {
    chat <- fake_chat(list(bad))
    testthat::expect_error(
      liminal2::assess_liminal_space(
        ask = "Build us a churn model.",
        chat = chat,
        parallel = FALSE
      ),
      class = "liminal_error_llm_score"
    )
  }
})

testthat::test_that("invalid asks and situations are rejected", {
  chat <- fake_chat(rep(3L, 7L))

  testthat::expect_error(
    liminal2::assess_liminal_space(ask = "", chat = chat, parallel = FALSE),
    class = "liminal_error_input"
  )
  testthat::expect_error(
    liminal2::assess_liminal_space(ask = 1, chat = chat, parallel = FALSE),
    class = "liminal_error_input"
  )
  testthat::expect_error(
    liminal2::assess_liminal_space(
      ask = c("a", "b"),
      chat = chat,
      parallel = FALSE
    ),
    class = "liminal_error_input"
  )
  testthat::expect_error(
    liminal2::assess_liminal_space(
      ask = "a",
      situation = 5,
      chat = chat,
      parallel = FALSE
    ),
    class = "liminal_error_input"
  )
})

testthat::test_that("invalid weights abort before any LLM call", {
  stop_chat <- list(
    chat_structured = function(...) {
      stop("the LLM must not be called with invalid weights")
    }
  )
  bad_weights <- rep(0.2, 7)
  names(bad_weights) <- liminal_dimension_names

  testthat::expect_error(
    liminal2::assess_liminal_space(
      ask = "Build us a churn model.",
      weights = bad_weights,
      chat = stop_chat,
      parallel = FALSE
    ),
    class = "liminal_error_weights"
  )
})

testthat::test_that("a dimension that fails once is retried", {
  withr::local_options(liminal2.backoff_base = 0.01)

  # The first call fails; the retry and all later dimensions succeed.
  assessment <- liminal2::assess_liminal_space(
    ask = "Build us a churn model.",
    chat = failing_chat(fail_until = 1L),
    parallel = FALSE
  )

  testthat::expect_s3_class(assessment, "liminal_assessment")
  testthat::expect_true(all(assessment$raw_scores == 3L))
})

testthat::test_that("a dimension that always fails aborts", {
  withr::local_options(liminal2.backoff_base = 0.01)

  testthat::expect_error(
    liminal2::assess_liminal_space(
      ask = "Build us a churn model.",
      chat = failing_chat(),
      parallel = FALSE
    ),
    class = "liminal_error_llm_transport"
  )
})
