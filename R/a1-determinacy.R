#' @keywords internal
.prepare_definitions <- function(defs, name = "defs") {
  if (is.null(defs)) {
    stop("`", name, "` must be supplied.", call. = FALSE)
  }
  if (!is.data.frame(defs) && !is.matrix(defs)) {
    stop("`", name, "` must be a data.frame or a matrix.", call. = FALSE)
  }
  defs <- as.data.frame(defs, stringsAsFactors = FALSE)
  if (nrow(defs) < 1L || ncol(defs) < 2L) {
    stop(
      "`", name, "` must contain at least one unit and two definitions.",
      call. = FALSE
    )
  }
  values <- unlist(defs, use.names = FALSE)
  values <- values[!is.na(values)]
  if (length(values) == 0L) {
    stop("`", name, "` must contain at least one observed label.",
      call. = FALSE
    )
  }
  levels <- sort(unique(as.character(values)))
  out <- lapply(defs, function(column) {
    factor(as.character(column), levels = levels)
  })
  out <- as.data.frame(out, stringsAsFactors = FALSE)
  names(out) <- names(defs)
  out
}

#' @keywords internal
.kripp_alpha_nominal <- function(defs) {
  defs <- .prepare_definitions(defs)
  levels <- levels(defs[[1L]])
  k <- length(levels)
  if (k < 2L) {
    stop(
      "Krippendorff's alpha is undefined when all labels belong to one ",
      "category.",
      call. = FALSE
    )
  }
  coincidence <- matrix(0, nrow = k, ncol = k,
    dimnames = list(levels, levels)
  )
  for (unit in seq_len(nrow(defs))) {
    values <- unlist(defs[unit, , drop = TRUE], use.names = FALSE)
    values <- values[!is.na(values)]
    m <- length(values)
    if (m < 2L) {
      next
    }
    counts <- tabulate(as.integer(values), nbins = k)
    for (i in seq_len(k)) {
      for (j in seq_len(k)) {
        if (i == j) {
          coincidence[i, j] <- coincidence[i, j] +
            counts[i] * (counts[i] - 1L) / (m - 1L)
        } else {
          coincidence[i, j] <- coincidence[i, j] +
            counts[i] * counts[j] / (m - 1L)
        }
      }
    }
  }
  total <- sum(coincidence)
  if (!is.finite(total) || total <= 1) {
    stop("Krippendorff's alpha requires at least two observations.",
      call. = FALSE
    )
  }
  marginals <- rowSums(coincidence)
  observed <- (sum(coincidence) - sum(diag(coincidence))) / total
  expected <- (sum(marginals)^2 - sum(marginals^2)) / (total * (total - 1))
  if (!is.finite(expected) || expected <= 0) {
    stop(
      "Krippendorff's alpha is undefined because expected disagreement ",
      "is zero.",
      call. = FALSE
    )
  }
  1 - observed / expected
}

#' @keywords internal
.fleiss_kappa <- function(defs) {
  defs <- .prepare_definitions(defs)
  if (anyNA(defs)) {
    stop("Fleiss' kappa requires complete data.", call. = FALSE)
  }
  units <- nrow(defs)
  coders <- ncol(defs)
  if (coders < 2L) {
    stop("Fleiss' kappa requires at least two coders.", call. = FALSE)
  }
  levels <- levels(defs[[1L]])
  k <- length(levels)
  if (k < 2L) {
    stop("Fleiss' kappa is undefined for a single category.", call. = FALSE)
  }
  counts <- matrix(0, nrow = units, ncol = k)
  for (unit in seq_len(units)) {
    values <- unlist(defs[unit, , drop = TRUE], use.names = FALSE)
    counts[unit, ] <- tabulate(as.integer(values), nbins = k)
  }
  p_unit <- (rowSums(counts^2) - coders) / (coders * (coders - 1))
  p_bar <- mean(p_unit)
  p_j <- colSums(counts) / (units * coders)
  p_e <- sum(p_j^2)
  if (!is.finite(p_e) || p_e >= 1) {
    stop("Fleiss' kappa is undefined when expected agreement is one.",
      call. = FALSE
    )
  }
  (p_bar - p_e) / (1 - p_e)
}

#' @keywords internal
.confident_learning_score <- function(defs) {
  defs <- .prepare_definitions(defs)
  values <- as.matrix(defs)
  item_levels <- levels(defs[[1L]])
  confidences <- apply(values, 1L, function(row) {
    row <- row[!is.na(row)]
    if (length(row) == 0L) {
      return(NA_real_)
    }
    codes <- as.integer(factor(row, levels = item_levels))
    max(tabulate(codes, nbins = length(item_levels)) / length(row))
  })
  confidences <- confidences[!is.na(confidences)]
  if (length(confidences) == 0L) {
    stop("No units with observed labels were found.", call. = FALSE)
  }
  mean(confidences)
}

#' @keywords internal
.determinacy_estimate <- function(defs, method) {
  switch(method,
    krippendorff = .kripp_alpha_nominal(defs),
    fleiss = .fleiss_kappa(defs),
    confident_learning = .confident_learning_score(defs),
    hybrid = min(
      .clamp_warn(.kripp_alpha_nominal(defs), "Krippendorff's alpha"),
      .clamp_warn(
        .confident_learning_score(defs),
        "confident-learning score"
      )
    ),
    stop("Unknown determinacy method.", call. = FALSE)
  )
}

#' Label determinacy
#'
#' Estimates how strongly rival operational definitions of the same target
#' agree. The default estimator is Krippendorff's alpha with the nominal
#' metric. Units with fewer than two observed labels are dropped.
#'
#' @param defs A data.frame or matrix with one row per unit and one column per
#'   rival definition (coder). Missing labels are allowed.
#' @param method One of `"krippendorff"`, `"fleiss"`,
#'   `"confident_learning"` or `"hybrid"`.
#' @param n_boot Number of bootstrap resamples used for the percentile
#'   confidence interval. Set to zero to skip the bootstrap.
#' @param seed Optional integer seed. The caller's random-number state is
#'   restored on exit.
#' @param conf_level Confidence level for the bootstrap interval.
#'
#' @return A finite scalar in the unit interval. The bootstrap interval and
#'   estimate metadata are attached as attributes.
#' @export
#' @examples
#' defs <- data.frame(
#'   first = c("yes", "no", "yes", "no"),
#'   second = c("yes", "no", "no", "no")
#' )
#' label_determinacy(defs, n_boot = 0)
label_determinacy <- function(defs,
                              method = c(
                                "krippendorff", "fleiss",
                                "confident_learning", "hybrid"
                              ),
                              n_boot = 1000,
                              seed = NULL,
                              conf_level = 0.95) {
  method <- match.arg(method)
  .check_positive_integer(n_boot, "n_boot", minimum = 0L)
  .check_prob(conf_level, "conf_level")
  prepared <- .prepare_definitions(defs)
  estimate <- .determinacy_estimate(prepared, method)
  estimate <- .clamp_warn(
    estimate,
    paste0("label determinacy (", method, ")")
  )

  interval <- c(NA_real_, NA_real_)
  boot_values <- numeric(0)
  if (n_boot > 0L) {
    units <- nrow(prepared)
    boot_values <- .run_seeded(seed, function() {
      vapply(seq_len(n_boot), function(iteration) {
        index <- sample.int(units, units, replace = TRUE)
        value <- tryCatch(
          suppressWarnings(
            .determinacy_estimate(prepared[index, , drop = FALSE], method)
          ),
          error = function(e) NA_real_
        )
        if (!is.finite(value)) {
          return(NA_real_)
        }
        min(max(value, 0), 1)
      }, numeric(1))
    })
    boot_values <- boot_values[is.finite(boot_values)]
    if (length(boot_values) >= 2L) {
      alpha <- (1 - conf_level) / 2
      interval <- stats::quantile(
        boot_values,
        probs = c(alpha, 1 - alpha),
        names = FALSE,
        na.rm = TRUE
      )
    }
  }

  attr(estimate, "ci") <- interval
  attr(estimate, "boot") <- boot_values
  attr(estimate, "method") <- method
  attr(estimate, "n_units") <- nrow(prepared)
  attr(estimate, "n_definitions") <- ncol(prepared)
  estimate
}
