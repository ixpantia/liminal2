#' Ordinal liminality anchors
#'
#' A reference typology for users who want an approximate band without
#' computing the six components. The anchors run from arithmetic tasks to
#' normative judgements through causal counterfactuals.
#'
#' @return A data.frame with case names, strength bands and liminality
#'   bands.
#' @export
#' @examples
#' liminal_anchors()
liminal_anchors <- function() {
  data.frame(
    case = c(
      "arithmetic",
      "deterministic_rule",
      "supervised_prediction",
      "ambiguous_prediction",
      "causal_counterfactual",
      "normative_judgement"
    ),
    A_lower = c(0.95, 0.90, 0.70, 0.45, 0.15, 0.00),
    A_upper = c(1.00, 0.95, 0.90, 0.70, 0.45, 0.15),
    L_lower = c(0.00, 0.05, 0.10, 0.30, 0.55, 0.85),
    L_upper = c(0.05, 0.10, 0.30, 0.55, 0.85, 1.00),
    description = c(
      "Closed-form arithmetic with a unique answer",
      "Codified rule whose adjudication is reproducible",
      "Well-posed prediction with observable outcomes",
      "Prediction with contested labels or unstable models",
      "Counterfactual whose outcome cannot be observed directly",
      "Normative choice with no fact of the matter"
    ),
    stringsAsFactors = FALSE
  )
}

#' Look up a liminality case
#'
#' @param case A case name from [liminal_anchors()]. Partial matching is
#'   allowed. When missing, the full anchor table is returned.
#'
#' @return A list with the case, band and description, or the full table
#'   when `case` is missing.
#' @export
#' @examples
#' liminal_case("supervised")
liminal_case <- function(case) {
  anchors <- liminal_anchors()
  if (missing(case) || is.null(case)) {
    return(anchors)
  }
  if (!is.character(case) || length(case) != 1L) {
    stop("`case` must be a single case name.", call. = FALSE)
  }
  matched <- match.arg(case, anchors$case)
  row <- anchors[anchors$case == matched, , drop = FALSE]
  list(
    case = row$case,
    A_band = c(lower = row$A_lower, upper = row$A_upper),
    L_band = c(lower = row$L_lower, upper = row$L_upper),
    description = row$description
  )
}
