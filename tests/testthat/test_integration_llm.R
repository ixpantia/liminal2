# Opt-in integration with the live Panama endpoint.
#
# These tests make real LLM calls (6 scenarios x 7 prompts) and are
# skipped unless PANAMA_API_KEY is set. They validate the pipeline end
# to end; failures are a signal about the prompts or the model, never
# a licence to tune the anchors on these fixtures (see the package
# specification, sections 6 and 11.2).

testthat::test_that("the scenario ladder is strictly increasing live", {
  testthat::skip_if(Sys.getenv("PANAMA_API_KEY") == "")

  measures <- vapply(
    liminal_scenario_fixtures,
    function(fixture) {
      assessment <- liminal2::assess_liminal_space(
        ask = fixture$ask,
        situation = fixture$situation
      )

      testthat::expect_s3_class(assessment, "liminal_assessment")
      testthat::expect_true(is.finite(assessment$liminality))
      testthat::expect_true(assessment$liminality > 0)
      testthat::expect_true(assessment$liminality <= 1)
      testthat::expect_true(all(assessment$raw_scores >= 0))
      testthat::expect_true(all(assessment$raw_scores <= 10))
      testthat::expect_identical(
        names(assessment$raw_scores),
        liminal_dimension_names
      )

      assessment$liminality
    },
    numeric(1)
  )

  testthat::expect_identical(names(measures), names(liminal_scenario_fixtures))
  testthat::expect_true(all(diff(measures) > 0))
})

testthat::test_that("live measurement is reproducible within a run", {
  testthat::skip_if(Sys.getenv("PANAMA_API_KEY") == "")

  fixture <- liminal_scenario_fixtures$S1
  args <- list(ask = fixture$ask, situation = fixture$situation)

  first <- liminal2::assess_liminal_space(
    ask = args$ask,
    situation = args$situation
  )
  second <- liminal2::assess_liminal_space(
    ask = args$ask,
    situation = args$situation
  )

  testthat::expect_equal(first$raw_scores, second$raw_scores)
  testthat::expect_equal(first$liminality, second$liminality)
})
