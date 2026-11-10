# Regenerates the model-comparison benchmark cached in
# inst/extdata/model-comparison-results.parquet and rendered by
# vignettes/model-comparison.Rmd.
#
# The script makes live LLM calls
# (models x 6 scenarios x 7 prompts x 2 repetitions) and requires the
# environment variable PANAMA_API_KEY. The key is read from the
# environment; it is never stored in this file.
#
# Usage:
#   R CMD INSTALL -l "$(rv library)" .
#   rv run data-raw/model_comparison.R

library(liminal2)
library(arrow)
library(httr2)
library(purrr)
library(tibble)

base_url <- Sys.getenv(
  "PANAMA_BASE_URL",
  "https://panama.ixpantia.ixops.ai/v1"
)
api_key <- Sys.getenv("PANAMA_API_KEY")
if (!nzchar(api_key)) {
  stop("Set PANAMA_API_KEY before running this script.")
}

# Discover every model currently available on the endpoint, together
# with the prices it advertises. ellmer's bundled price table does not
# know this provider, so cost is computed from these fields.
models_response <- httr2::request(base_url) |>
  httr2::req_url_path_append("models") |>
  httr2::req_headers(Authorization = paste("Bearer", api_key)) |>
  httr2::req_perform() |>
  httr2::resp_body_json()

model_info <- tibble::tibble(
  model = purrr::map_chr(models_response$data, "id"),
  input_cost = purrr::map_dbl(
    models_response$data,
    "input_cost_per_million"
  ),
  output_cost = purrr::map_dbl(
    models_response$data,
    "output_cost_per_million"
  )
)

message("Benchmarking models: ", paste(model_info$model, collapse = ", "))

# The six test scenarios, ask and situation verbatim, from the test
# suite's fixtures (specification, section 12.3). They are used as
# benchmark inputs only, never to tune the prompts.
source("tests/testthat/helper_scenarios.R")
scenarios <- liminal_scenario_fixtures

# The benchmark calls the package's own orchestration pieces directly
# so that token usage and cost can be collected per call
# (assess_liminal_space() does not return cost). Internal helpers are
# used deliberately: this is a development script, not shipped code.
score_type <- liminal2:::liminal_score_type()

rows <- list()

for (model in model_info$model) {
  chat <- liminal2::liminal_chat(model = model)
  prices <- model_info[model_info$model == model, ]

  for (scenario_name in names(scenarios)) {
    fixture <- scenarios[[scenario_name]]
    prompts <- liminal2::liminal_prompts(fixture$ask, fixture$situation)

    for (rep in c(1L, 2L)) {
      message(sprintf(
        "model %s, scenario %s, repetition %d",
        model,
        scenario_name,
        rep
      ))

      results <- tryCatch(
        ellmer::parallel_chat_structured(
          chat,
          prompts,
          type = score_type,
          include_tokens = TRUE,
          max_active = 7L,
          rpm = 500,
          on_error = "continue"
        ),
        error = function(cnd) cnd
      )

      if (inherits(results, "error")) {
        stop("The concurrent attempt failed: ", conditionMessage(results))
      }

      for (i in seq_along(prompts)) {
        dimension <- names(prompts)[[i]]
        error <- if (".error" %in% names(results)) {
          results$.error[[i]]
        } else {
          NULL
        }

        raw_score <- NA_integer_
        input_tokens <- NA_real_
        output_tokens <- NA_real_

        if (inherits(error, "error")) {
          # Failed dimensions are retried sequentially with backoff;
          # the token usage of the failed attempts is not recoverable.
          raw_score <- liminal2:::score_with_retry(
            prompts[[i]],
            dimension,
            chat
          )
        } else {
          raw_score <- liminal2:::validate_llm_score(
            results$score[[i]],
            dimension
          )
          input_tokens <- results$input_tokens[[i]]
          output_tokens <- results$output_tokens[[i]]
        }

        cost <- (
          input_tokens / 1e6 * prices$input_cost +
            output_tokens / 1e6 * prices$output_cost
        )

        rows[[length(rows) + 1L]] <- tibble::tibble(
          benchmark_date = format(Sys.Date()),
          model = model,
          scenario = scenario_name,
          rep = rep,
          dimension = dimension,
          raw_score = raw_score,
          input_tokens = input_tokens,
          output_tokens = output_tokens,
          cost = cost
        )
      }
    }
  }
}

results <- purrr::list_rbind(rows)

arrow::write_parquet(
  results,
  "inst/extdata/model-comparison-results.parquet"
)

message(
  "Wrote ",
  nrow(results),
  " rows to inst/extdata/model-comparison-results.parquet"
)
