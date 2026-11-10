#' Default dimension weights
#'
#' Returns the default weights used by [measure_liminal_space()]: one
#' equal weight per dimension, summing to 1. Equal weights are a
#' deliberate contract: changing them would change every published
#' score, so non-default weights must always be passed explicitly.
#'
#' @return A named numeric vector of length seven with one weight per
#'   liminal dimension, in canonical dimension order.
#' @export
#' @examples
#' liminal2::default_weights()
default_weights <- function() {
  weights <- rep(
    1 / length(liminal_dimension_names),
    length(liminal_dimension_names)
  )
  stats::setNames(weights, liminal_dimension_names)
}

#' Measure the size of a liminal space
#'
#' Computes the liminality `L = 1 - prod(scores ^ weights)`, the
#' complement of the weighted geometric mean of the seven condition
#' scores on the liminal dimensions. On the condition scale, 1 means a
#' dimension's condition is satisfied (no obstacle) and 0 means it is
#' absent (maximal obstacle), so `L = 0` is a fully closed gap and
#' `L = 1` is a fully open one.
#'
#' @param scores Either a named numeric vector with one value per
#'   liminal dimension (order irrelevant, names must be exactly the
#'   canonical set), or a scenario list carrying such a vector in its
#'   `scores` element. Values must be finite and inside `[0, 1]`.
#' @param weights A named numeric vector with one non-negative weight
#'   per dimension, summing to 1. Defaults to [default_weights()].
#'
#' @return A single finite numeric in `[0, 1]`.
#' @export
#' @examples
#' scores <- c(
#'   shared_meaning = 0.9,
#'   stable_ground = 0.8,
#'   convergent_answers = 0.7,
#'   knowable_from_observables = 0.6,
#'   judgeable = 0.5,
#'   action_identifiable = 0.4,
#'   tradeoff_agreed = 0.3
#' )
#' liminal2::measure_liminal_space(scores)
measure_liminal_space <- function(scores, weights = default_weights()) {
  scores <- extract_scores(scores)
  weights <- validate_weights(weights)

  # Align by name so that the order of scores and weights cannot
  # affect the result.
  scores <- scores[liminal_dimension_names]
  weights <- weights[liminal_dimension_names]

  1 - prod(scores^weights)
}
