# The LLM layer ---------------------------------------------------------
#
# One client, one structured-output schema and two orchestration paths
# (concurrent by default, sequential as fallback and for tests), per
# the package specification, sections 5.1 to 5.4.

#' Build the LLM client used for dimension scoring
#'
#' Creates an `ellmer` chat client for the OpenAI-compatible Panama
#' endpoint. All configuration comes from the environment; the API key
#' is never stored in source. Temperature is fixed at 0 for scoring,
#' because scores must be comparable across business cases.
#'
#' @param model The model name. Defaults to the `LIMINAL2_MODEL`
#'   environment variable, falling back to `"glm-5.3"`.
#' @param base_url The endpoint URL. Defaults to the `PANAMA_BASE_URL`
#'   environment variable, falling back to the Panama endpoint.
#' @param api_key The bearer key. Defaults to the `PANAMA_API_KEY`
#'   environment variable; an informative error is raised when unset.
#'
#' @return An ellmer `Chat` object.
#' @export
#' @examples
#' \donttest{
#' if (nzchar(Sys.getenv("PANAMA_API_KEY"))) {
#'   chat <- liminal2::liminal_chat()
#' }
#' }
liminal_chat <- function(
  model = Sys.getenv("LIMINAL2_MODEL", "glm-5.3"),
  base_url = Sys.getenv(
    "PANAMA_BASE_URL",
    "https://panama.ixpantia.ixops.ai/v1"
  ),
  api_key = Sys.getenv("PANAMA_API_KEY")
) {
  if (!nzchar(api_key)) {
    cli::cli_abort(
      c(
        "No API key found for the LLM endpoint.",
        "i" = "Set the {.envvar PANAMA_API_KEY} environment variable."
      ),
      class = "liminal_error_input"
    )
  }

  # Sys.getenv() returns "" for variables that are set but empty, so
  # the defaults are applied again explicitly.
  if (!nzchar(model)) {
    model <- "glm-5.3"
  }
  if (!nzchar(base_url)) {
    base_url <- "https://panama.ixpantia.ixops.ai/v1"
  }

  ellmer::chat_openai_compatible(
    base_url = base_url,
    name = "Panama",
    credentials = api_key,
    model = model,
    params = ellmer::params(temperature = 0)
  )
}

# The structured-output schema shared by the sequential and the
# concurrent path: a single integer named `score`.
liminal_score_type <- function() {
  ellmer::type_object(
    score = ellmer::type_integer(
      "Liminal-space score from 0 (small) to 10 (large)."
    )
  )
}

# Validates one raw score returned by the model. No silent clamping or
# re-weighting: a repaired score would break comparability across
# business cases, so invalid output is an error that names the
# dimension and the offending value.
validate_llm_score <- function(score, dimension) {
  if (!is.numeric(score) || length(score) != 1L || !is.finite(score)) {
    cli::cli_abort(
      c(
        "The model returned an invalid score for {.val {dimension}}.",
        "i" = paste(
          "Expected a single finite whole number from 0 to 10,",
          "got {.val {deparse1(score)}}."
        )
      ),
      class = "liminal_error_llm_score"
    )
  }

  if (score < 0 || score > 10) {
    cli::cli_abort(
      c(
        paste(
          "The model returned a score outside 0 to 10 for",
          "{.val {dimension}}."
        ),
        "i" = "Got {.val {deparse1(score)}}."
      ),
      class = "liminal_error_llm_score"
    )
  }

  if (score != trunc(score)) {
    cli::cli_abort(
      c(
        "The model returned a non-whole score for {.val {dimension}}.",
        "i" = "Got {.val {deparse1(score)}}."
      ),
      class = "liminal_error_llm_score"
    )
  }

  as.integer(score)
}

# Scores one dimension with at most `max_attempts` attempts and
# exponential backoff between transport failures. Invalid model output
# is not retried: it fails fast with liminal_error_llm_score.
score_with_retry <- function(prompt, dimension, chat, max_attempts = 3L) {
  # Tests shorten the backoff through this option so the retry logic
  # can be exercised without sleeping for seconds.
  delay <- getOption("liminal2.backoff_base", 1)

  attempt <- 1L
  repeat {
    response <- tryCatch(
      chat$chat_structured(prompt, type = liminal_score_type()),
      error = function(cnd) cnd
    )

    if (!inherits(response, "error")) {
      return(validate_llm_score(response$score, dimension))
    }

    if (attempt >= max_attempts) {
      cli::cli_abort(
        c(
          paste(
            "Dimension {.val {dimension}} could not be scored",
            "after {max_attempts} attempts."
          ),
          "x" = conditionMessage(response)
        ),
        class = "liminal_error_llm_transport"
      )
    }

    Sys.sleep(delay)
    delay <- delay * 2
    attempt <- attempt + 1L
  }
}

# Sequential path: one dimension at a time, each with its own retry
# loop. Also the fallback for dimensions that failed in the concurrent
# attempt, and the path used with the fake chats of the unit tests.
score_dimensions_sequential <- function(prompts, chat) {
  raw <- purrr::imap_int(prompts, function(prompt, dimension) {
    score_with_retry(prompt, dimension, chat)
  })
  stats::setNames(raw, names(prompts))
}

# Scores the seven rendered prompts. Concurrent by default through
# ellmer's async I/O; failures are retried sequentially with backoff.
score_dimensions <- function(
  prompts,
  chat,
  parallel = TRUE,
  max_active = 7L,
  rpm = 500
) {
  if (!isTRUE(parallel)) {
    return(score_dimensions_sequential(prompts, chat))
  }

  results <- tryCatch(
    ellmer::parallel_chat_structured(
      chat,
      prompts,
      type = liminal_score_type(),
      max_active = max_active,
      rpm = rpm,
      on_error = "continue"
    ),
    error = function(cnd) cnd
  )

  if (inherits(results, "error")) {
    # The concurrent attempt itself failed before any request was
    # answered; the sequential path retries per dimension.
    return(score_dimensions_sequential(prompts, chat))
  }

  raw <- as.list(rep(NA_integer_, length(prompts)))
  names(raw) <- names(prompts)

  for (i in seq_along(prompts)) {
    dimension <- names(prompts)[[i]]
    error <- parallel_row_error(results, i)

    if (inherits(error, "error")) {
      # Retry failed dimensions sequentially with backoff.
      raw[[i]] <- score_with_retry(prompts[[i]], dimension, chat)
    } else {
      raw[[i]] <- validate_llm_score(
        parallel_row_score(results, i),
        dimension
      )
    }
  }

  unlist(raw, use.names = TRUE)
}

# One row of a parallel_chat_structured() result carries either a
# converted score or an error object in an .error column. These
# helpers keep the extraction tolerant of the returned shape.
parallel_row_score <- function(results, i) {
  if (tibble::is_tibble(results)) {
    results$score[[i]]
  } else {
    results[[i]]$score
  }
}

parallel_row_error <- function(results, i) {
  if (tibble::is_tibble(results) && ".error" %in% names(results)) {
    results$.error[[i]]
  } else {
    NULL
  }
}
