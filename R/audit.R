#' @keywords internal
.max_univariate_auc <- function(X, y) {
  design <- .make_design(X)
  columns <- setdiff(colnames(design), "(Intercept)")
  if (length(columns) == 0L) {
    return(NA_real_)
  }
  values <- vapply(
    columns,
    function(column) {
      value <- design[, column]
      if (length(unique(value)) < 2L) {
        return(NA_real_)
      }
      auc <- .auc(y, value)
      if (!is.finite(auc)) {
        return(NA_real_)
      }
      max(auc, 1 - auc)
    },
    numeric(1)
  )
  values <- values[is.finite(values)]
  if (length(values) == 0L) {
    return(NA_real_)
  }
  max(values)
}

#' Audit a model for label leakage
#'
#' Combines discriminability with a univariate leakage probe and a label
#' permutation test. A model is flagged when cross-validated
#' discriminability is high and a single feature is almost perfectly
#' associated with the label.
#'
#' @param X A data.frame or matrix of features.
#' @param y A binary outcome.
#' @param fit_predict Optional model adapter, as in [discriminability()].
#' @param threshold Discriminability threshold for flagging.
#' @param folds Number of cross-validation folds.
#' @param repeats Number of cross-validation repeats.
#' @param permutations Number of label permutations for the probe.
#' @param seed Optional integer seed. The caller's random-number state is
#'   restored on exit.
#'
#' @return An object of class `liminality_audit`.
#' @export
#' @examples
#' set.seed(1)
#' X <- data.frame(x = rnorm(300))
#' y <- as.integer(X$x > 0)
#' audit_leakage(X, y, permutations = 10)
audit_leakage <- function(X,
                          y,
                          fit_predict = NULL,
                          threshold = 0.9,
                          folds = 5,
                          repeats = 2,
                          permutations = 50,
                          seed = NULL) {
  .check_data(X, "X")
  .check_prob(threshold, "threshold")
  folds <- .check_positive_integer(folds, "folds", minimum = 2L)
  repeats <- .check_positive_integer(repeats, "repeats", minimum = 1L)
  permutations <- .check_positive_integer(
    permutations, "permutations",
    minimum = 1L
  )
  if (length(y) != nrow(X)) {
    stop("`y` must have one value per row of `X`.", call. = FALSE)
  }
  binary_y <- .as_binary(y)
  result <- .run_seeded(seed, function() {
    a4 <- discriminability(
      X, binary_y,
      fit_predict = fit_predict,
      folds = folds,
      repeats = repeats,
      correction = "none",
      seed = NULL
    )
    observed <- .max_univariate_auc(X, binary_y)
    null_values <- vapply(seq_len(permutations), function(iteration) {
      .max_univariate_auc(X, sample(binary_y))
    }, numeric(1))
    p_value <- if (is.finite(observed)) {
      (1 + sum(null_values >= observed, na.rm = TRUE)) /
        (permutations + 1)
    } else {
      NA_real_
    }
    list(a4 = a4, observed = observed, p_value = p_value)
  })
  flagged <- isTRUE(as.numeric(result$a4) >= threshold) &&
    isTRUE(is.finite(result$observed)) &&
    isTRUE(result$observed >= 0.95)
  output <- list(
    flagged = flagged,
    a4 = unname(as.numeric(result$a4)),
    max_univariate_auc = result$observed,
    permutation_p_value = result$p_value,
    threshold = threshold,
    permutations = permutations,
    n = nrow(X),
    seed = seed
  )
  class(output) <- "liminality_audit"
  output
}

#' Print a leakage audit
#'
#' @param x A `liminality_audit` object.
#' @param digits Number of digits to display.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @export
print.liminality_audit <- function(x, digits = 3, ...) {
  cat("leakage audit\n")
  cat("  flagged:", x$flagged, "\n")
  cat("  discriminability:", format(round(x$a4, digits)), "\n")
  cat(
    "  max univariate AUC:",
    format(round(x$max_univariate_auc, digits)), "\n"
  )
  cat(
    "  permutation p-value:",
    format(round(x$permutation_p_value, digits)), "\n"
  )
  invisible(x)
}
