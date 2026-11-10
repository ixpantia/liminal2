# The LLM layer ---------------------------------------------------------
#
# One client, one structured-output schema and two orchestration paths
# (concurrent by default, sequential as fallback and for tests), per the
# package specification, sections 5.1 to 5.4.
#
# The scoring transport is implemented directly on httr2 rather than on
# ellmer's chat_structured() / parallel_chat_structured(): the Panama
# gateway returns valid JSON labelled text/plain, which ellmer's strict
# response content-type check rejects. httr2::resp_body_json() accepts
# check_type = FALSE, and httr2::req_perform_parallel() provides the
# concurrency. ellmer still builds the client (configuration,
# credentials, temperature, provenance) and renders the prompts.

#' Build the LLM client used for dimension scoring
#'
#' Creates an `ellmer` chat client for the OpenAI-compatible Panama
#' endpoint. All configuration comes from the environment; the API key
#' is never stored in source. Temperature is fixed at 0 for scoring,
#' because scores must be comparable across business cases.
#'
#' The chat object carries the configuration and the provenance of the
#' client; the scoring calls themselves are issued by the package's
#' `httr2` transport (see `assess_liminal_space()`).
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
    credentials = function() api_key,
    model = model,
    params = ellmer::params(temperature = 0)
  )
}

# The wire schema for the structured output: a single integer field
# named `score`, sent as the chat-completions `response_format`.
liminal_score_schema <- function() {
  list(
    type = "json_schema",
    json_schema = list(
      name = "liminal_score",
      schema = list(
        type = "object",
        properties = list(
          score = list(
            type = "integer",
            description = paste(
              "Liminal-space score from 0 (small) to 10 (large)."
            )
          )
        ),
        required = list("score"),
        additionalProperties = FALSE
      )
    )
  )
}

# True for real ellmer chats. Injected fake chats (the unit tests) are
# plain lists and keep their own $chat_structured() method.
chat_is_ellmer <- function(chat) {
  inherits(chat, "Chat")
}

# Builds one chat-completions request from the chat's configuration:
# base URL, credentials, model and temperature all come from the
# ellmer chat object, so the transport stays in sync with the client.
liminal_score_request <- function(chat, prompt) {
  provider <- chat$get_provider()
  model <- chat$get_model_object()
  temperature <- model@params$temperature
  if (is.null(temperature)) {
    temperature <- 0
  }
  authorization <- paste("Bearer", provider@credentials())

  httr2::request(paste0(provider@base_url, "/chat/completions")) |>
    httr2::req_headers(Authorization = authorization) |>
    httr2::req_body_json(list(
      model = model@name,
      temperature = temperature,
      messages = list(list(role = "user", content = prompt)),
      response_format = liminal_score_schema()
    ))
}

# Parses one chat-completions response into a validated-shape result.
# The gateway labels JSON bodies text/plain, so the content-type check
# is disabled explicitly: the body is known to be JSON.
parse_score_response <- function(resp) {
  body <- httr2::resp_body_json(resp, check_type = FALSE)
  content <- body$choices[[1]]$message$content
  score <- jsonlite::parse_json(content)$score

  input_tokens <- body$usage$prompt_tokens
  output_tokens <- body$usage$completion_tokens

  list(
    score = score,
    input_tokens = if (is.null(input_tokens)) NA_real_ else input_tokens,
    output_tokens = if (is.null(output_tokens)) NA_real_ else output_tokens
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

# Performs one structured call against the chat. Real ellmer chats go
# through the package's httr2 transport; injected fake chats keep
# their $chat_structured() method.
chat_structured_call <- function(chat, prompt) {
  if (chat_is_ellmer(chat)) {
    liminal_score_request(chat, prompt) |>
      httr2::req_perform() |>
      parse_score_response()
  } else {
    chat$chat_structured(prompt, type = liminal_score_schema())
  }
}

# Scores one dimension with at most `max_attempts` attempts and
# exponential backoff between transport failures. Invalid model output
# is not retried: it fails fast with liminal_error_llm_score.
score_call_with_retry <- function(
  prompt,
  dimension,
  chat,
  max_attempts = 3L
) {
  # Tests shorten the backoff through this option so the retry logic
  # can be exercised without sleeping for seconds.
  delay <- getOption("liminal2.backoff_base", 1)

  attempt <- 1L
  repeat {
    response <- tryCatch(
      chat_structured_call(chat, prompt),
      error = function(cnd) cnd
    )

    if (!inherits(response, "error")) {
      return(list(
        score = validate_llm_score(response$score, dimension),
        input_tokens = response$input_tokens %||% NA_real_,
        output_tokens = response$output_tokens %||% NA_real_
      ))
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
  purrr::imap(prompts, function(prompt, dimension) {
    score_call_with_retry(prompt, dimension, chat)
  })
}

# Scores the seven rendered prompts and returns the per-dimension
# detail: raw score and token usage. Concurrent by default; failed
# dimensions are retried sequentially with backoff.
score_dimensions_detail <- function(
  prompts,
  chat,
  parallel = TRUE,
  max_active = 7L,
  rpm = 500
) {
  if (!isTRUE(parallel) || !chat_is_ellmer(chat)) {
    results <- score_dimensions_sequential(prompts, chat)
    return(tidy_score_results(results))
  }

  reqs <- purrr::map(prompts, function(prompt) {
    httr2::req_throttle(
      liminal_score_request(chat, prompt),
      capacity = rpm,
      fill_time_s = 60
    )
  })

  resps <- tryCatch(
    httr2::req_perform_parallel(
      reqs,
      max_active = max_active,
      on_error = "continue"
    ),
    error = function(cnd) cnd
  )

  if (inherits(resps, "error")) {
    # The concurrent attempt itself failed before any request was
    # answered; the sequential path retries per dimension.
    results <- score_dimensions_sequential(prompts, chat)
    return(tidy_score_results(results))
  }

  results <- stats::setNames(
    as.list(rep(list(NULL), length(prompts))),
    names(prompts)
  )

  for (i in seq_along(prompts)) {
    dimension <- names(prompts)[[i]]
    parsed <- if (inherits(resps[[i]], "error") || is.null(resps[[i]])) {
      resps[[i]]
    } else {
      tryCatch(parse_score_response(resps[[i]]), error = function(cnd) cnd)
    }

    if (inherits(parsed, "error") || is.null(parsed)) {
      # Retry failed dimensions sequentially with backoff.
      results[[i]] <- score_call_with_retry(prompts[[i]], dimension, chat)
    } else {
      results[[i]] <- list(
        score = validate_llm_score(parsed$score, dimension),
        input_tokens = parsed$input_tokens %||% NA_real_,
        output_tokens = parsed$output_tokens %||% NA_real_
      )
    }
  }

  tidy_score_results(results)
}

# Assembles per-dimension results into the canonical tibble.
tidy_score_results <- function(results) {
  tibble::tibble(
    dimension = names(results),
    raw_score = purrr::map_int(results, function(result) result$score),
    input_tokens = purrr::map_dbl(
      results,
      function(result) result$input_tokens %||% NA_real_
    ),
    output_tokens = purrr::map_dbl(
      results,
      function(result) result$output_tokens %||% NA_real_
    )
  )
}

# Scores the seven rendered prompts, returning the named raw-score
# vector used by assess_liminal_space().
score_dimensions <- function(
  prompts,
  chat,
  parallel = TRUE,
  max_active = 7L,
  rpm = 500
) {
  detail <- score_dimensions_detail(
    prompts,
    chat = chat,
    parallel = parallel,
    max_active = max_active,
    rpm = rpm
  )
  stats::setNames(detail$raw_score, detail$dimension)
}
