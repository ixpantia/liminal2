#' Construct validity correlation
#'
#' Correlates liminality scores with an external criterion. This is a
#' descriptive construct-validity check, not a calibration claim.
#'
#' @param x A `liminality_assessment`, a list of assessments, or a numeric
#'   vector of liminality scores.
#' @param external A numeric external criterion with one value per
#'   assessment.
#' @param method `"pearson"`, `"spearman"` or `"kendall"`.
#'
#' @return An object of class `liminality_validity`.
#' @export
#' @examples
#' x <- c(0.1, 0.2, 0.4, 0.8)
#' validate_index(x, c(1, 2, 2, 4), method = "spearman")
validate_index <- function(x,
                           external,
                           method = c("pearson", "spearman", "kendall")) {
  method <- match.arg(method)
  if (inherits(x, "liminality_assessment")) {
    values <- x$L
  } else if (is.list(x)) {
    values <- vapply(x, function(item) {
      if (inherits(item, "liminality_assessment")) {
        return(item$L)
      }
      if (is.numeric(item) && length(item) == 1L) {
        return(as.numeric(item))
      }
      stop("List elements must be assessments or numeric scores.",
        call. = FALSE
      )
    }, numeric(1))
  } else if (is.numeric(x)) {
    values <- x
  } else {
    stop("`x` must be assessments or numeric liminality scores.",
      call. = FALSE
    )
  }
  if (!is.numeric(external) || length(external) != length(values)) {
    stop("`external` must be numeric and match the length of `x`.",
      call. = FALSE
    )
  }
  if (length(values) < 3L) {
    stop("At least three paired observations are required.",
      call. = FALSE
    )
  }
  test <- stats::cor.test(values, external, method = method)
  result <- list(
    estimate = unname(test$estimate),
    p_value = test$p.value,
    method = method,
    n = length(values),
    alternative = test$alternative
  )
  class(result) <- "liminality_validity"
  result
}

#' Print a construct-validity result
#'
#' @param x A `liminality_validity` object.
#' @param digits Number of digits to display.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @export
print.liminality_validity <- function(x, digits = 3, ...) {
  cat("construct validity\n")
  cat("  method:", x$method, "\n")
  cat("  correlation:", format(round(x$estimate, digits)), "\n")
  cat("  p-value:", format(round(x$p_value, digits)), "\n")
  cat("  n:", x$n, "\n")
  invisible(x)
}
