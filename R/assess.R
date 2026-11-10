#' Assess the size of the liminal space of a business ask
#'
#' Sends the business ask (and the optional situation) through seven
#' independent, versioned dimension prompts to a large language model,
#' converts the seven raw scores (0 = small space, 10 = large space) to
#' the internal condition scale, and aggregates them with
#' [measure_liminal_space()].
#'
#' The seven dimension calls run concurrently by default; concurrency
#' affects timing only, never the scores, because the calls share no
#' state and results are re-assembled in canonical dimension order.
#'
#' @param ask A single non-empty character string: the business ask,
#'   verbatim, in whatever language it was written.
#' @param situation `NULL` or a single character string describing the
#'   context: data state, history, constraints, known ambiguities.
#' @param weights A named numeric vector with one non-negative weight
#'   per dimension, summing to 1. Defaults to [default_weights()].
#'   Invalid weights abort before any LLM call is made.
#' @param chat An ellmer `Chat` object used for all seven calls.
#'   Defaults to [liminal_chat()], which reads its configuration from
#'   environment variables. Inject a custom chat to control the client
#'   in tests or scripts.
#' @param parallel Logical; run the seven dimension calls concurrently
#'   (default) or sequentially.
#' @param max_active Maximum number of simultaneous requests in the
#'   concurrent path; at most one per dimension.
#' @param rpm Maximum number of requests per minute in the concurrent
#'   path.
#'
#' @return A list of class `liminal_assessment` with elements:
#'   * `liminality` — the final score in `[0, 1]`;
#'   * `raw_scores` — the seven model scores, integers in `[0, 10]`;
#'   * `scores` — the seven condition scores in `[0, 1]`;
#'   * `weights` — the weights used;
#'   * `model`, `base_url` — provenance of the client;
#'   * `prompt_versions` — the template version used per dimension;
#'   * `ask`, `situation` — the inputs, verbatim.
#' @export
#' @examples
#' \donttest{
#' if (nzchar(Sys.getenv("PANAMA_API_KEY"))) {
#'   assessment <- liminal2::assess_liminal_space(
#'     ask = paste(
#'       "Give us indicators of project execution built from the",
#'       "task and timesheet data we already have."
#'     ),
#'     situation = paste(
#'       "Three years of in-house task and timesheet data with",
#'       "stable definitions."
#'     )
#'   )
#'   print(assessment)
#' }
#' }
assess_liminal_space <- function(
  ask,
  situation = NULL,
  weights = default_weights(),
  chat = liminal_chat(),
  parallel = TRUE,
  max_active = 7L,
  rpm = 500
) {
  validate_ask(ask)
  validate_situation(situation)

  # Validate weights before spending any LLM calls on them.
  weights <- validate_weights(weights)

  prompts <- liminal_prompts(ask, situation)

  raw_scores <- score_dimensions(
    prompts,
    chat = chat,
    parallel = parallel,
    max_active = max_active,
    rpm = rpm
  )

  scores <- convert_scores(raw_scores)
  liminality <- measure_liminal_space(scores, weights)

  registry <- liminal_dimensions()

  structure(
    list(
      liminality = liminality,
      raw_scores = raw_scores,
      scores = scores,
      weights = weights[liminal_dimension_names],
      model = chat_model(chat),
      base_url = chat_base_url(chat),
      prompt_versions = stats::setNames(
        registry$prompt_version,
        registry$name
      ),
      ask = ask,
      situation = situation
    ),
    class = "liminal_assessment"
  )
}

# The LLM returns the size of the space on a 0-10 scale; the
# aggregation expects the adequacy of the condition on a 0-1 scale.
# This fixed inversion is the only place where the two scales meet.
convert_scores <- function(raw_scores) {
  scores <- 1 - raw_scores / 10
  stats::setNames(scores, names(raw_scores))
}

# Provenance extraction; fake chats used in tests do not implement
# these methods, so fall back to NA.
chat_model <- function(chat) {
  tryCatch(
    chat$get_model_object()@name,
    error = function(cnd) NA_character_
  )
}

chat_base_url <- function(chat) {
  tryCatch(
    chat$get_provider()@base_url,
    error = function(cnd) NA_character_
  )
}

#' @export
#' @noRd
print.liminal_assessment <- function(x, ...) {
  cli::cli_rule("Liminal space assessment")
  cli::cli_text(
    "Size of the liminal space (0 = closed, 1 = open): {
      sprintf('%.2f', x$liminality)
    }"
  )
  cli::cli_text("")
  cli::cli_text("Raw dimension scores (0 = small space, 10 = large):")
  for (dimension in names(x$raw_scores)) {
    cli::cli_text("  {dimension}: {x$raw_scores[[dimension]]}")
  }
  cli::cli_text("")
  model <- if (is.na(x$model)) "unknown" else x$model
  cli::cli_text("Model: {model}")
  cli::cli_text("Prompt versions: {x$prompt_versions[[1]]}")
  invisible(x)
}
