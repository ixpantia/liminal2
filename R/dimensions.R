#' Liminality dimensions
#'
#' Splits the six components into the epistemic (`a1`, `a2`), structural
#' (`a3`, `a4`) and normative (`a5`, `a6`) dimensions. Each dimension is the
#' mean of `1 - a_k` over its two components.
#'
#' @param a A named numeric vector with components `a1` to `a6`.
#'
#' @return A named numeric vector with `L1`, `L2` and `L3`.
#' @export
#' @examples
#' liminality_dimensions(c(
#'   a1 = 0.9, a2 = 0.9, a3 = 0.7,
#'   a4 = 0.7, a5 = 0.5, a6 = 0.5
#' ))
liminality_dimensions <- function(a) {
  if (!is.numeric(a) || is.null(names(a)) ||
    !setequal(names(a), .component_names())) {
    stop(
      "`a` must be a named numeric vector with components a1 to a6.",
      call. = FALSE
    )
  }
  a <- a[.component_names()]
  .check_prob_vector(a, "a")
  c(
    L1 = mean(1 - a[c("a1", "a2")]),
    L2 = mean(1 - a[c("a3", "a4")]),
    L3 = mean(1 - a[c("a5", "a6")])
  )
}

#' @keywords internal
.dimension_summary <- function(a) {
  values <- liminality_dimensions(a)
  dominant <- names(values)[which.max(values)]
  list(
    values = values,
    dominant = dominant,
    unbounded = identical(dominant, "L3") && values[["L3"]] > 0.5
  )
}
