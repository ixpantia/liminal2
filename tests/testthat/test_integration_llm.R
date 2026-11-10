# Opt-in integration with the live Panama endpoint.
#
# These tests make real LLM calls and are skipped unless PANAMA_API_KEY
# is set. They validate the pipeline end to end.
#
# The scenario ladder is recorded as a diagnostic, not asserted: the
# offline aggregation tests already pin the strict ordering on
# scripted scores, and per the specification (sections 6 and 11.2) a
# live inversion is a signal about the prompts or the model — evidence
# for the model-comparison benchmark and the anchor review of section
# 14.1 — never a licence to tune the anchors on these fixtures.

testthat::test_that("live assessments are structurally valid", {
  testthat::skip_if(Sys.getenv("PANAMA_API_KEY") == "")

  for (fixture in liminal_scenario_fixtures) {
    assessment <- liminal2::assess_liminal_space(
      ask = fixture$ask,
      situation = fixture$situation
    )

    testthat::expect_s3_class(assessment, "liminal_assessment")
    testthat::expect_true(is.finite(assessment$liminality))
    testthat::expect_true(assessment$liminality >= 0)
    testthat::expect_true(assessment$liminality <= 1)
    testthat::expect_true(all(assessment$raw_scores >= 0))
    testthat::expect_true(all(assessment$raw_scores <= 10))
    testthat::expect_identical(
      names(assessment$raw_scores),
      liminal_dimension_names
    )
    testthat::expect_true(all(assessment$raw_scores == trunc(
      assessment$raw_scores
    )))
    testthat::expect_true(all(assessment$prompt_versions == "1.1.0"))
  }
})

testthat::test_that("the observed scenario ladder is recorded", {
  testthat::skip_if(Sys.getenv("PANAMA_API_KEY") == "")

  measures <- vapply(
    liminal_scenario_fixtures,
    function(fixture) {
      liminal2::assess_liminal_space(
        ask = fixture$ask,
        situation = fixture$situation
      )$liminality
    },
    numeric(1)
  )

  # The observed ladder goes into the test log, where it is evidence
  # for the benchmark vignette and the anchor review. The strict
  # ordering is asserted offline, on scripted scores.
  message(
    "observed ladder: ",
    paste(
      sprintf("%s=%.3f", names(measures), measures),
      collapse = " "
    )
  )

  testthat::expect_identical(
    names(measures),
    names(liminal_scenario_fixtures)
  )
  testthat::expect_true(all(is.finite(measures)))
  testthat::expect_true(all(measures >= 0))
  testthat::expect_true(all(measures <= 1))
})

testthat::test_that("temperature 0 keeps run-to-run jitter bounded", {
  testthat::skip_if(Sys.getenv("PANAMA_API_KEY") == "")

  # Temperature 0 does not imply bitwise determinism on this backend:
  # batched inference makes even greedy sampling vary between runs.
  # The guarantee the package relies on is comparability, not
  # identity, so the assertion bounds the jitter instead of demanding
  # exact equality.
  fixture <- liminal_scenario_fixtures$S1

  first <- liminal2::assess_liminal_space(
    ask = fixture$ask,
    situation = fixture$situation
  )
  second <- liminal2::assess_liminal_space(
    ask = fixture$ask,
    situation = fixture$situation
  )

  score_delta <- abs(first$raw_scores - second$raw_scores)
  liminality_delta <- abs(first$liminality - second$liminality)

  message(
    "run-to-run jitter: max score delta ",
    max(score_delta),
    ", liminality delta ",
    sprintf("%.3f", liminality_delta)
  )

  testthat::expect_true(max(score_delta) <= 3)
  testthat::expect_true(liminality_delta <= 0.1)
})
