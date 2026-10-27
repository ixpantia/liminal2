#' @keywords internal
.smoothed_divergence <- function(ref_counts, cur_counts, eps) {
  n_ref <- sum(ref_counts)
  n_cur <- sum(cur_counts)
  if (n_ref == 0 || n_cur == 0) {
    return(0)
  }
  n_bins <- length(ref_counts)
  ref_raw <- ref_counts / n_ref
  cur_raw <- cur_counts / n_cur
  ref <- (ref_counts + eps) / (n_ref + eps * n_bins)
  cur <- (cur_counts + eps) / (n_cur + eps * n_bins)
  terms <- ifelse(
    ref_raw == 0 & cur_raw == 0,
    0,
    ifelse(ref > 0 & cur > 0, (cur - ref) * log(cur / ref), 0)
  )
  sum(terms)
}

#' @keywords internal
.numeric_psi <- function(ref, cur, bins, eps) {
  ref <- ref[!is.na(ref)]
  cur <- cur[!is.na(cur)]
  if (length(ref) == 0L || length(cur) == 0L) {
    return(0)
  }
  if (length(unique(ref)) < 3L) {
    return(0)
  }
  probs <- seq(0, 1, length.out = bins + 1L)
  breaks <- unique(stats::quantile(
    ref,
    probs = probs,
    na.rm = TRUE,
    names = FALSE,
    type = 7
  ))
  if (length(breaks) < 3L) {
    return(0)
  }
  breaks[1L] <- -Inf
  breaks[length(breaks)] <- Inf
  ref_bin <- cut(ref, breaks = breaks, include.lowest = TRUE, right = TRUE)
  cur_bin <- cut(cur, breaks = breaks, include.lowest = TRUE, right = TRUE)
  n_bins <- length(breaks) - 1L
  ref_counts <- tabulate(as.integer(ref_bin), nbins = n_bins)
  cur_counts <- tabulate(as.integer(cur_bin), nbins = n_bins)
  .smoothed_divergence(ref_counts, cur_counts, eps)
}

#' @keywords internal
.categorical_psi <- function(ref, cur, eps) {
  ref <- as.character(ref)
  cur <- as.character(cur)
  ref[is.na(ref)] <- "<NA>"
  cur[is.na(cur)] <- "<NA>"
  if (length(ref) == 0L || length(cur) == 0L) {
    return(0)
  }
  levels <- sort(unique(c(ref, cur)))
  ref_counts <- tabulate(match(ref, levels), nbins = length(levels))
  cur_counts <- tabulate(match(cur, levels), nbins = length(levels))
  .smoothed_divergence(ref_counts, cur_counts, eps)
}

#' @keywords internal
.categorical_cramers_v <- function(ref, cur) {
  ref <- as.character(ref)
  cur <- as.character(cur)
  ref[is.na(ref)] <- "<NA>"
  cur[is.na(cur)] <- "<NA>"
  levels <- sort(unique(c(ref, cur)))
  table <- rbind(
    tabulate(match(ref, levels), nbins = length(levels)),
    tabulate(match(cur, levels), nbins = length(levels))
  )
  table <- table[, colSums(table) > 0, drop = FALSE]
  if (ncol(table) < 2L) {
    return(0)
  }
  test <- tryCatch(
    suppressWarnings(stats::chisq.test(table, correct = FALSE)),
    error = function(e) NULL
  )
  if (is.null(test) || !is.finite(test$statistic)) {
    return(0)
  }
  value <- sqrt(
    test$statistic / (sum(table) * (min(dim(table)) - 1L))
  )
  min(max(value, 0), 1)
}

#' @keywords internal
.feature_stability <- function(ref, cur, type, bins, eps) {
  is_numeric <- is.numeric(ref) && is.numeric(cur)
  if (type == "psi") {
    if (is_numeric) {
      .numeric_psi(ref, cur, bins, eps)
    } else {
      .categorical_psi(ref, cur, eps)
    }
  } else if (type == "ks") {
    if (is_numeric) {
      ref <- ref[!is.na(ref)]
      cur <- cur[!is.na(cur)]
      if (length(ref) < 2L || length(cur) < 2L) {
        return(0)
      }
      statistic <- tryCatch(
        suppressWarnings(stats::ks.test(ref, cur)$statistic),
        error = function(e) 0
      )
      min(max(as.numeric(statistic), 0), 1)
    } else {
      .categorical_cramers_v(ref, cur)
    }
  } else {
    if (is_numeric) {
      ref <- ref[!is.na(ref)]
      cur <- cur[!is.na(cur)]
      if (length(ref) == 0L || length(cur) == 0L) {
        return(0)
      }
      if (length(unique(ref)) < 3L) {
        return(0)
      }
      breaks <- unique(stats::quantile(
        ref,
        probs = seq(0, 1, length.out = bins + 1L),
        na.rm = TRUE,
        names = FALSE
      ))
      if (length(breaks) < 3L) {
        return(0)
      }
      breaks[1L] <- -Inf
      breaks[length(breaks)] <- Inf
      ref_bin <- cut(ref, breaks = breaks, include.lowest = TRUE)
      cur_bin <- cut(cur, breaks = breaks, include.lowest = TRUE)
      n_bins <- length(breaks) - 1L
      ref_counts <- tabulate(as.integer(ref_bin), nbins = n_bins)
      cur_counts <- tabulate(as.integer(cur_bin), nbins = n_bins)
      n_ref <- sum(ref_counts)
      n_cur <- sum(cur_counts)
      ref_p <- (ref_counts + eps) / (n_ref + eps * n_bins)
      cur_p <- (cur_counts + eps) / (n_cur + eps * n_bins)
      sum((cur_p - ref_p)^2 / ref_p)
    } else {
      .categorical_cramers_v(ref, cur)
    }
  }
}

#' Construct stability
#'
#' Measures temporal drift between adjacent equal-count time folds. The
#' default is the mean Population Stability Index (PSI). The PSI is mapped to
#' the unit interval with `exp(-lambda * PSI)`, where the default `lambda`
#' makes PSI = 0.25 correspond to a stability score of 0.5.
#'
#' @param X A data.frame or matrix of features.
#' @param time_index A numeric or date vector with one value per row of `X`.
#' @param k Number of equal-count time folds.
#' @param bins Number of reference quantile bins for numeric features.
#' @param eps Laplace smoothing constant.
#' @param lambda Positive scale used to map drift to the unit interval.
#' @param type Drift statistic: `"psi"`, `"ks"` or `"chisq"`.
#'
#' @return A finite scalar in (0, 1] with drift diagnostics attached.
#' @export
#' @examples
#' set.seed(1)
#' X <- data.frame(value = rnorm(200))
#' temporal_stability(X, time_index = seq_len(200), k = 4)
temporal_stability <- function(X,
                               time_index,
                               k = 4,
                               bins = 10,
                               eps = 1e-6,
                               lambda = log(2) / 0.25,
                               type = c("psi", "ks", "chisq")) {
  .check_data(X, "X")
  type <- match.arg(type)
  k <- .check_positive_integer(k, "k", minimum = 2L)
  bins <- .check_positive_integer(bins, "bins", minimum = 2L)
  .check_scalar_number(eps, "eps", lower = 0, lower_open = TRUE)
  .check_scalar_number(
    lambda, "lambda",
    lower = 0, lower_open = TRUE
  )
  if (length(time_index) != nrow(X)) {
    stop("`time_index` must have one value per row of `X`.",
      call. = FALSE
    )
  }
  if (anyNA(time_index)) {
    stop("`time_index` must not contain missing values.", call. = FALSE)
  }
  n <- nrow(X)
  if (k > n) {
    stop("`k` cannot exceed the number of rows.", call. = FALSE)
  }
  unique_times <- length(unique(time_index))
  if (k > unique_times) {
    stop(
      "`k` cannot exceed the number of unique time values.",
      call. = FALSE
    )
  }
  order_index <- order(time_index, method = "radix")
  fold_sorted <- ((seq_len(n) - 1L) * k) %/% n + 1L
  fold_of_row <- integer(n)
  fold_of_row[order_index] <- fold_sorted
  feature_drift <- matrix(
    NA_real_,
    nrow = k - 1L,
    ncol = ncol(X),
    dimnames = list(paste0("fold_", seq_len(k - 1L)), names(X))
  )
  for (pair in seq_len(k - 1L)) {
    ref_index <- which(fold_of_row == pair)
    cur_index <- which(fold_of_row == pair + 1L)
    for (feature in seq_len(ncol(X))) {
      feature_drift[pair, feature] <- .feature_stability(
        X[ref_index, feature],
        X[cur_index, feature],
        type = type,
        bins = bins,
        eps = eps
      )
    }
  }
  fold_means <- rowMeans(feature_drift, na.rm = TRUE)
  mean_drift <- mean(fold_means[is.finite(fold_means)])
  if (!is.finite(mean_drift)) {
    mean_drift <- 0
  }
  score <- exp(-lambda * mean_drift)
  score <- .clamp_warn(score, "construct stability")
  attr(score, "drift") <- mean_drift
  attr(score, "fold_drift") <- fold_means
  attr(score, "feature_drift") <- feature_drift
  attr(score, "type") <- type
  attr(score, "k") <- k
  score
}
