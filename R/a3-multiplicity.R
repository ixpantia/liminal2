#' @keywords internal
.stratified_holdout <- function(y, proportion) {
  holdout <- integer(0)
  for (class in sort(unique(y))) {
    index <- which(y == class)
    index <- index[sample.int(length(index))]
    size <- max(1L, floor(length(index) * proportion))
    size <- min(size, length(index) - 1L)
    holdout <- c(holdout, index[seq_len(size)])
  }
  sort(holdout)
}

#' @keywords internal
.candidate_predictions <- function(X_train, y_train, X_validation,
                                   X_holdout, fit_predict, variant, B) {
  if (variant == "penalty" && is.null(fit_predict)) {
    design_train <- .make_design(X_train)
    design_validation <- .make_design(
      X_validation,
      colnames(design_train)
    )
    design_holdout <- .make_design(X_holdout, colnames(design_train))
    n_lambda <- max(2L, min(as.integer(B), 50L))
    fits <- .ridge_logistic_path(design_train, y_train, n_lambda)
    validation <- lapply(fits, function(fit) {
      prediction <- .predict_ridge(fit, design_validation)
      attr(prediction, "engine") <- "ridge"
      prediction
    })
    holdout <- lapply(fits, function(fit) {
      .predict_ridge(fit, design_holdout)
    })
    return(list(
      validation = validation,
      holdout = holdout,
      variant = "penalty"
    ))
  }

  used_variant <- variant
  if (variant == "penalty") {
    used_variant <- "subsample"
    warning(
      "A custom `fit_predict` cannot generate a penalty path; ",
      "the subsample variant was used.",
      call. = FALSE
    )
  }
  n_train <- nrow(X_train)
  sample_size <- if (used_variant == "bootstrap") {
    n_train
  } else {
    max(2L, floor(0.8 * n_train))
  }
  validation <- vector("list", B)
  holdout <- vector("list", B)
  for (iteration in seq_len(B)) {
    if (used_variant == "bootstrap") {
      index <- sample.int(n_train, n_train, replace = TRUE)
    } else {
      index <- sample.int(n_train, sample_size, replace = FALSE)
    }
    candidate_y <- y_train[index]
    if (length(unique(candidate_y)) < 2L) {
      next
    }
    pair <- .fit_predict_pair(
      fit_predict,
      X_train[index, , drop = FALSE],
      candidate_y,
      X_validation,
      X_holdout
    )
    validation[[iteration]] <- pair$first
    holdout[[iteration]] <- pair$second
  }
  keep <- vapply(validation, function(value) !is.null(value), logical(1))
  list(
    validation = validation[keep],
    holdout = holdout[keep],
    variant = used_variant
  )
}

#' Predictive multiplicity
#'
#' Estimates Rashomon-set ambiguity on a held-out set. Candidate models are
#' generated with a ridge penalty path, by bootstrap resampling, or by
#' subsampling. The score is one minus the aggregate per-instance ambiguity.
#'
#' @section Binary ambiguity bound:
#' With the binary majority-vote definition, per-instance ambiguity is
#' `1 - max(pbar, 1 - pbar)`, which lies between zero and 0.5. The aggregate
#' score therefore has a floor of 0.5. The authored S4 and S5 component
#' targets fall below this floor and cannot be reached by this estimator; the
#' benchmark acceptance criteria are stated in terms of the composite `L`.
#'
#' @param X A data.frame or matrix of features.
#' @param y A binary outcome coded as 0/1, logical, character or a two-level
#'   factor.
#' @param fit_predict Optional model adapter. Either a function
#'   `function(X_train, y_train, X_new)` returning probabilities, or a list
#'   with `fit` and `predict` functions. When `NULL`, an internal ridge
#'   logistic path is used for `variant = "penalty"`.
#' @param variant Candidate-generation strategy: `"penalty"`, `"bootstrap"`
#'   or `"subsample"`.
#' @param eps Tolerance around the best validation metric.
#' @param B Number of bootstrap/subsample candidates, or the maximum number
#'   of penalty-path candidates.
#' @param holdout Fraction of rows reserved for the final ambiguity estimate.
#' @param aggregate Whether to aggregate ambiguity by `"max"` or `"mean"`.
#' @param seed Optional integer seed. The caller's random-number state is
#'   restored on exit.
#'
#' @return A finite scalar in the unit interval with Rashomon diagnostics
#'   attached.
#' @export
#' @examples
#' set.seed(1)
#' X <- data.frame(x = rnorm(200))
#' y <- as.integer(X$x > 0)
#' predictive_multiplicity(
#'   X, y,
#'   variant = "subsample", B = 10, seed = 42
#' )
predictive_multiplicity <- function(
    X,
    y,
    fit_predict = NULL,
    variant = c("penalty", "bootstrap", "subsample"),
    eps = 0.02,
    B = 200,
    holdout = 0.3,
    aggregate = c("max", "mean"),
    seed = NULL) {
  .check_data(X, "X")
  variant <- match.arg(variant)
  aggregate <- match.arg(aggregate)
  .check_prob(eps, "eps")
  B <- .check_positive_integer(B, "B", minimum = 2L)
  .check_scalar_number(
    holdout, "holdout",
    lower = 0, upper = 1, lower_open = TRUE, upper_open = TRUE
  )
  if (length(y) != nrow(X)) {
    stop("`y` must have one value per row of `X`.", call. = FALSE)
  }
  binary_y <- .as_binary(y)
  class_counts <- table(binary_y)
  if (length(class_counts) < 2L || any(class_counts < 4L)) {
    stop("Both classes must have at least four observations.",
      call. = FALSE
    )
  }

  result <- .run_seeded(seed, function() {
    holdout_index <- .stratified_holdout(binary_y, holdout)
    train_index <- setdiff(seq_len(nrow(X)), holdout_index)
    train_y <- binary_y[train_index]
    if (min(table(train_y)) < 2L) {
      stop("The training split must contain both classes.", call. = FALSE)
    }
    validation_index <- .stratified_holdout(train_y, 0.25)
    if (min(table(train_y[validation_index])) < 2L ||
      min(table(train_y[-validation_index])) < 2L) {
      validation_index <- seq_along(train_y)
      fit_index <- seq_along(train_y)
    } else {
      fit_index <- setdiff(seq_along(train_y), validation_index)
    }
    X_fit <- X[train_index[fit_index], , drop = FALSE]
    y_fit <- train_y[fit_index]
    X_validation <- X[train_index[validation_index], , drop = FALSE]
    y_validation <- train_y[validation_index]
    X_holdout <- X[holdout_index, , drop = FALSE]
    y_holdout <- binary_y[holdout_index]

    candidates <- .candidate_predictions(
      X_fit, y_fit, X_validation, X_holdout,
      fit_predict = fit_predict,
      variant = variant,
      B = B
    )
    if (length(candidates$holdout) < 2L) {
      return(list(
        score = 1,
        warning = "fewer than two candidate models were available",
        n_candidates = length(candidates$holdout),
        n_rashomon = 0L,
        ambiguity = numeric(0),
        variant = candidates$variant,
        holdout_size = length(holdout_index),
        validation_size = length(validation_index)
      ))
    }
    metrics <- vapply(
      candidates$validation,
      function(prediction) .binary_metric(y_validation, prediction),
      numeric(1)
    )
    best <- max(metrics, na.rm = TRUE)
    keep <- which(is.finite(metrics) & metrics >= best - eps)
    if (length(keep) < 2L) {
      return(list(
        score = 1,
        warning = "fewer than two models were inside the Rashomon set",
        n_candidates = length(metrics),
        n_rashomon = length(keep),
        ambiguity = numeric(0),
        variant = candidates$variant,
        holdout_size = length(holdout_index),
        validation_size = length(validation_index)
      ))
    }
    votes <- vapply(
      candidates$holdout[keep],
      function(prediction) as.numeric(prediction >= 0.5),
      numeric(length(y_holdout))
    )
    if (is.null(dim(votes))) {
      votes <- matrix(votes, ncol = 1L)
    }
    mean_vote <- rowMeans(votes)
    ambiguity <- 1 - pmax(mean_vote, 1 - mean_vote)
    aggregated <- if (aggregate == "max") {
      max(ambiguity)
    } else {
      mean(ambiguity)
    }
    list(
      score = 1 - aggregated,
      warning = NULL,
      n_candidates = length(metrics),
      n_rashomon = length(keep),
      ambiguity = ambiguity,
      variant = candidates$variant,
      holdout_size = length(holdout_index),
      validation_size = length(validation_index)
    )
  })

  if (!is.null(result$warning)) {
    warning(result$warning, call. = FALSE)
  }
  score <- min(max(result$score, 0), 1)
  attr(score, "n_candidates") <- result$n_candidates
  attr(score, "n_rashomon") <- result$n_rashomon
  attr(score, "ambiguity") <- result$ambiguity
  attr(score, "aggregate") <- aggregate
  attr(score, "eps") <- eps
  attr(score, "variant") <- result$variant
  attr(score, "holdout_size") <- result$holdout_size
  attr(score, "validation_size") <- result$validation_size
  score
}
