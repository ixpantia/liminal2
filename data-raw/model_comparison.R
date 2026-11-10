# Regenerates the model-comparison benchmark cached in
# inst/extdata/model-comparison-results.parquet and rendered by
# vignettes/model-comparison.Rmd.
#
# The script makes live LLM calls
# (models x 6 scenarios x 7 prompts x 2 repetitions) and requires the
# environment variable PANAMA_API_KEY. The key is read from the
# environment or from a gitignored .env file in the repository root;
# it is never stored in this file.
#
# Usage:
#   R CMD INSTALL -l "$(rv library)" .
#   rv run data-raw/model_comparison.R

library(liminal2)
library(arrow)
library(httr2)
library(purrr)
library(tibble)

# Load local development secrets from .env when they are not already
# exported. The file is gitignored and excluded from the package build.
env_file <- ".env"
if (file.exists(env_file)) {
  env_lines <- trimws(readLines(env_file, warn = FALSE))
  env_lines <- env_lines[
    nzchar(env_lines) & !startsWith(env_lines, "#")
  ]
  for (env_line in env_lines) {
    env_key <- sub("=.*$", "", env_line)
    env_value <- sub("^[^=]*=", "", env_line)
    env_value <- gsub("^['\"]|['\"]$", "", env_value)
    if (nzchar(env_key) && !nzchar(Sys.getenv(env_key))) {
      do.call(Sys.setenv, stats::setNames(list(env_value), env_key))
    }
  }
}

base_url <- Sys.getenv(
  "PANAMA_BASE_URL",
  "https://panama.ixpantia.ixops.ai/v1"
)
api_key <- Sys.getenv("PANAMA_API_KEY")
if (!nzchar(api_key)) {
  stop(
    "Set PANAMA_API_KEY in the environment or in the repository's ",
    ".env file before running this script."
  )
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

# Prompt versions are recorded per row, so a run made under one
# version can never be silently pooled with another.
dimensions <- liminal2::liminal_dimensions()
prompt_versions <- stats::setNames(
  dimensions$prompt_version,
  dimensions$name
)

out_path <- Sys.getenv(
  "LIMINAL2_BENCHMARK_OUT",
  "inst/extdata/model-comparison-results.parquet"
)

# The benchmark calls the package's own orchestration directly, so
# that token usage and cost can be collected per call
# (assess_liminal_space() does not return tokens). Internal helpers
# are used deliberately: this is a development script, not shipped
# code.
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

      detail <- liminal2:::score_dimensions_detail(prompts, chat)

      for (i in seq_len(nrow(detail))) {
        cost <- (
          detail$input_tokens[[i]] / 1e6 * prices$input_cost +
            detail$output_tokens[[i]] / 1e6 * prices$output_cost
        )

        rows[[length(rows) + 1L]] <- tibble::tibble(
          benchmark_date = format(Sys.Date()),
          prompt_version = unname(
            prompt_versions[[detail$dimension[[i]]]]
          ),
          model = model,
          scenario = scenario_name,
          rep = rep,
          dimension = detail$dimension[[i]],
          raw_score = detail$raw_score[[i]],
          input_tokens = detail$input_tokens[[i]],
          output_tokens = detail$output_tokens[[i]],
          cost = cost
        )
      }
    }
  }
}

results <- purrr::list_rbind(rows)

arrow::write_parquet(results, out_path)

message("Wrote ", nrow(results), " rows to ", out_path)
