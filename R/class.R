#' @keywords internal
.component_table <- function(x) {
  table <- data.frame(
    component = .component_names(),
    value = as.numeric(x$components),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
  if (!is.null(x$ci) && all(c("a1", "a2", "a3", "a4", "a5", "a6") %in%
    rownames(x$ci))) {
    table$lower <- x$ci[.component_names(), "lower"]
    table$upper <- x$ci[.component_names(), "upper"]
  }
  table
}

#' Print a liminality assessment
#'
#' @param x A `liminality_assessment` object.
#' @param digits Number of digits to display.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @export
print.liminality_assessment <- function(x, digits = 3, ...) {
  cat("liminality assessment\n")
  cat("  adjudication strength A:", format(round(x$A, digits)), "\n")
  cat("  liminality L:", format(round(x$L, digits)), "\n")
  if (!is.null(x$ci) && all(c("A", "L") %in% rownames(x$ci))) {
    cat(
      "  A interval:", format(round(x$ci["A", "lower"], digits)),
      "to", format(round(x$ci["A", "upper"], digits)), "\n"
    )
    cat(
      "  L interval:", format(round(x$ci["L", "lower"], digits)),
      "to", format(round(x$ci["L", "upper"], digits)), "\n"
    )
  }
  cat("  method:", x$method, "\n")
  cat("  dominant dimension:", x$dominant_dimension, "\n")
  if (isTRUE(x$unbounded)) {
    cat("  flag: normative liminality dominates above 0.5\n")
  }
  cat("\nComponents:\n")
  table <- .component_table(x)
  print(table, row.names = FALSE, digits = digits)
  cat("\nDimensions:\n")
  print(round(x$dimensions, digits))
  invisible(x)
}

#' Summarise a liminality assessment
#'
#' @param object A `liminality_assessment` object.
#' @param digits Number of digits to display.
#' @param ... Unused.
#'
#' @return An object of class `summary.liminality_assessment`.
#' @export
summary.liminality_assessment <- function(object, digits = 3, ...) {
  notices <- character(0)
  if (isTRUE(object$unbounded)) {
    notices <- c(
      notices,
      "Normative liminality dominates and exceeds 0.5."
    )
  }
  if (!is.null(object$bootstrap)) {
    draws <- object$bootstrap$draws
    sensitivity <- c(
      L_lower = min(draws$L, na.rm = TRUE),
      L_upper = max(draws$L, na.rm = TRUE)
    )
  } else {
    sensitivity <- NULL
  }
  result <- list(
    A = object$A,
    L = object$L,
    components = object$components,
    weights = object$weights,
    dimensions = object$dimensions,
    dominant_dimension = object$dominant_dimension,
    unbounded = object$unbounded,
    ci = object$ci,
    sensitivity = sensitivity,
    notices = notices,
    digits = digits
  )
  class(result) <- "summary.liminality_assessment"
  result
}

#' Print a liminality summary
#'
#' @param x A `summary.liminality_assessment` object.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @export
print.summary.liminality_assessment <- function(x, ...) {
  digits <- x$digits
  cat("liminality summary\n")
  cat("  A:", format(round(x$A, digits)),
    " L:", format(round(x$L, digits)), "\n"
  )
  cat("  dominant dimension:", x$dominant_dimension, "\n")
  if (!is.null(x$ci)) {
    cat("  bootstrap intervals:\n")
    print(round(x$ci, digits))
  }
  if (!is.null(x$sensitivity)) {
    cat("  bootstrap L range:",
      format(round(x$sensitivity[["L_lower"]], digits)),
      "to", format(round(x$sensitivity[["L_upper"]], digits)), "\n"
    )
  }
  if (length(x$notices) > 0L) {
    cat("  notices:\n")
    for (notice in x$notices) {
      cat("   -", notice, "\n")
    }
  }
  cat("  components:\n")
  print(round(x$components, digits))
  cat("  dimensions:\n")
  print(round(x$dimensions, digits))
  invisible(x)
}

#' Plot a liminality assessment
#'
#' Draws a component bar chart. Bootstrap intervals are shown when
#' available.
#'
#' @param x A `liminality_assessment` object.
#' @param ... Additional graphical arguments passed to [graphics::barplot()].
#'
#' @return The bar midpoints, invisibly.
#' @export
plot.liminality_assessment <- function(x, ...) {
  table <- .component_table(x)
  colors <- rep("grey70", nrow(table))
  colors[table$component %in% c("a1", "a2")] <- "#4C78A8"
  colors[table$component %in% c("a3", "a4")] <- "#F58518"
  colors[table$component %in% c("a5", "a6")] <- "#54A24B"
  midpoints <- graphics::barplot(
    table$value,
    names.arg = table$component,
    ylim = c(0, 1),
    col = colors,
    border = NA,
    ylab = "Component score",
    main = "Liminality components",
    ...
  )
  if (!is.null(table$lower)) {
    graphics::arrows(
      midpoints,
      table$lower,
      midpoints,
      table$upper,
      angle = 90,
      code = 3,
      length = 0.04
    )
  }
  invisible(midpoints)
}

#' Convert a liminality assessment to a data.frame
#'
#' @param x A `liminality_assessment` object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Unused.
#'
#' @return A one-row data.frame.
#' @export
as.data.frame.liminality_assessment <- function(x, row.names = NULL,
                                                optional = FALSE, ...) {
  data.frame(
    A = x$A,
    L = x$L,
    a1 = x$components[["a1"]],
    a2 = x$components[["a2"]],
    a3 = x$components[["a3"]],
    a4 = x$components[["a4"]],
    a5 = x$components[["a5"]],
    a6 = x$components[["a6"]],
    L1 = x$dimensions[["L1"]],
    L2 = x$dimensions[["L2"]],
    L3 = x$dimensions[["L3"]],
    dominant_dimension = x$dominant_dimension,
    unbounded = x$unbounded,
    method = x$method,
    stringsAsFactors = FALSE
  )
}

#' Print a liminality bootstrap
#'
#' @param x A `liminality_bootstrap` object.
#' @param digits Number of digits to display.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @export
print.liminality_bootstrap <- function(x, digits = 3, ...) {
  cat("liminality bootstrap\n")
  cat("  resamples:", x$B, " seed:", if (is.null(x$seed)) "NULL" else x$seed,
    "\n"
  )
  cat("  confidence level:", x$conf_level, "\n")
  print(round(x$ci, digits))
  invisible(x)
}

#' Print a weight-sensitivity result
#'
#' @param x A `liminality_sensitivity` object.
#' @param digits Number of digits to display.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @export
print.liminality_sensitivity <- function(x, digits = 3, ...) {
  cat("weight sensitivity\n")
  cat("  draws:", x$n, " seed:", if (is.null(x$seed)) "NULL" else x$seed,
    "\n"
  )
  cat("  L quantiles:\n")
  print(round(x$L_quantiles, digits))
  if (!is.null(x$ranking_fraction)) {
    cat("  ranking preserved:", round(x$ranking_fraction, digits), "\n")
  }
  invisible(x)
}
