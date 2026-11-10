# Input validation ------------------------------------------------------
#
# All user-facing failures are raised as conditions with a class that
# callers can catch programmatically:
#   * liminal_error_scores     - invalid dimension scores
#   * liminal_error_weights    - invalid weights
#   * liminal_error_input      - invalid ask or situation
#   * liminal_error_llm_score  - invalid model output
#   * liminal_error_llm_transport - the API could not be reached

validate_ask <- function(ask) {
  if (!rlang::is_string(ask) || !nzchar(trimws(ask))) {
    cli::cli_abort(
      "{.arg ask} must be a non-empty character string.",
      class = "liminal_error_input"
    )
  }
  ask
}

validate_situation <- function(situation) {
  if (is.null(situation)) {
    return(NULL)
  }
  if (!rlang::is_string(situation)) {
    cli::cli_abort(
      "{.arg situation} must be NULL or a single character string.",
      class = "liminal_error_input"
    )
  }
  situation
}

# Accepts either a named score vector or a scenario list carrying a
# $scores element, and always returns the validated score vector.
extract_scores <- function(scores) {
  if (is.null(scores)) {
    cli::cli_abort(
      "{.arg scores} must not be NULL.",
      class = "liminal_error_scores"
    )
  }

  if (is.list(scores)) {
    if (!rlang::has_name(scores, "scores")) {
      cli::cli_abort(
        c(
          "A scenario must be a list with a {.code scores} element.",
          "i" = paste(
            "Supply the score vector directly or through",
            "{.code scenario$scores}."
          )
        ),
        class = "liminal_error_scores"
      )
    }
    return(extract_scores(scores$scores))
  }

  validate_scores(scores)
}

validate_scores <- function(scores) {
  if (!is.numeric(scores)) {
    cli::cli_abort(
      "{.arg scores} must be a numeric vector.",
      class = "liminal_error_scores"
    )
  }

  score_names <- names(scores)
  if (
    is.null(score_names) ||
      any(is.na(score_names)) ||
      any(!nzchar(score_names))
  ) {
    cli::cli_abort(
      "{.arg scores} must carry one name per dimension.",
      class = "liminal_error_scores"
    )
  }

  if (length(scores) != length(liminal_dimension_names)) {
    cli::cli_abort(
      c(
        "{.arg scores} must have exactly
          {length(liminal_dimension_names)} values, one per dimension.",
        "i" = paste(
          "Expected dimensions:",
          paste(liminal_dimension_names, collapse = ", ")
        )
      ),
      class = "liminal_error_scores"
    )
  }

  if (anyDuplicated(score_names) > 0L) {
    cli::cli_abort(
      "Dimension names in {.arg scores} must be unique.",
      class = "liminal_error_scores"
    )
  }

  if (!setequal(score_names, liminal_dimension_names)) {
    cli::cli_abort(
      c(
        "{.arg scores} must contain exactly the liminal dimensions.",
        "i" = paste(
          "Expected dimensions:",
          paste(liminal_dimension_names, collapse = ", ")
        )
      ),
      class = "liminal_error_scores"
    )
  }

  if (!all(is.finite(scores))) {
    cli::cli_abort(
      paste(
        "{.arg scores} must be finite, without NA, NaN or",
        "infinite values."
      ),
      class = "liminal_error_scores"
    )
  }

  if (any(scores < 0) || any(scores > 1)) {
    cli::cli_abort(
      "{.arg scores} must lie inside the unit interval.",
      class = "liminal_error_scores"
    )
  }

  scores
}

validate_weights <- function(weights) {
  if (is.null(weights)) {
    cli::cli_abort(
      "{.arg weights} must not be NULL.",
      class = "liminal_error_weights"
    )
  }

  if (!is.numeric(weights)) {
    cli::cli_abort(
      "{.arg weights} must be a numeric vector.",
      class = "liminal_error_weights"
    )
  }

  weight_names <- names(weights)
  if (
    is.null(weight_names) ||
      any(is.na(weight_names)) ||
      any(!nzchar(weight_names))
  ) {
    cli::cli_abort(
      "{.arg weights} must carry one name per dimension.",
      class = "liminal_error_weights"
    )
  }

  if (anyDuplicated(weight_names) > 0L) {
    cli::cli_abort(
      "Dimension names in {.arg weights} must be unique.",
      class = "liminal_error_weights"
    )
  }

  if (!setequal(weight_names, liminal_dimension_names)) {
    cli::cli_abort(
      c(
        "{.arg weights} must contain exactly the liminal dimensions.",
        "i" = paste(
          "Expected dimensions:",
          paste(liminal_dimension_names, collapse = ", ")
        )
      ),
      class = "liminal_error_weights"
    )
  }

  if (!all(is.finite(weights))) {
    cli::cli_abort(
      paste(
        "{.arg weights} must be finite, without NA, NaN or",
        "infinite values."
      ),
      class = "liminal_error_weights"
    )
  }

  if (any(weights < 0)) {
    cli::cli_abort(
      "{.arg weights} must be non-negative.",
      class = "liminal_error_weights"
    )
  }

  if (!isTRUE(all.equal(sum(weights), 1))) {
    cli::cli_abort(
      "{.arg weights} must sum to 1.",
      class = "liminal_error_weights"
    )
  }

  weights
}
