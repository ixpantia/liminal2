#' Attainable discriminability
#'
#' Estimates repeated stratified k-fold cross-validated AUC and maps it to
#' the unit interval with `2 * AUC - 1`. A mean AUC below 0.5 is inverted
#' with a warning.
#'
#' @param X A data.frame or matrix of features.
#' @param y A binary outcome coded as 0/1, logical, character or a two-level
#'   factor.
#' @param fit_predict Optional model adapter. Either a function
#'   `function(X_train, y_train, X_new)` returning probabilities, or a list
#'   with `fit` and `predict` functions. When `NULL`, a logistic regression
#'   with a ridge fallback is used.
#' @param folds Number of stratified folds.
#' @param repeats Number of repeated cross-validation runs.
#' @param correction `"none"` or `"optimism"` for a 0.632 correction.
#' @param seed Optional integer seed. The caller's random-number state is
#'   restored on exit.
#'
#' @return A finite scalar in the unit interval with fold diagnostics attached.
#' @export
#' @examples
#' set.seed(1)
#' X <- data.frame(x = rnorm(200))
#' y <- as.integer(X$x + rnorm(200) > 0)
#' discriminability(X, y, folds = 3, repeats = 2)
discriminability <- function(X,
                             y,
                             fit_predict = NULL,
                             folds = 5,
                             repeats = 5,
                             correction = c("none", "optimism"),
                             seed = NULL) {
  .check_data(X, "X")
  correction <- match.arg(correction)
  folds <- .check_positive_integer(folds, "folds", minimum = 2L)
  repeats <- .check_positive_integer(repeats, "repeats", minimum = 1L)
  if (length(y) != nrow(X)) {
    stop("`y` must have one value per row of `X`.", call. = FALSE)
  }
  binary_y <- .as_binary(y)
  n <- length(binary_y)
  if (n < folds) {
    stop("The number of rows must be at least `folds`.", call. = FALSE)
  }

  result <- .run_seeded(seed, function() {
    fold_auc <- numeric(repeats * folds)
    position <- 0L
    skipped <- 0L
    engines <- character(0)
    for (repeat_index in seq_len(repeats)) {
      fold_id <- .stratified_fold_id(binary_y, folds)
      for (fold in seq_len(folds)) {
        test_index <- which(fold_id == fold)
        train_index <- which(fold_id != fold)
        position <- position + 1L
        test_y <- binary_y[test_index]
        if (length(unique(test_y)) < 2L ||
          length(unique(binary_y[train_index])) < 2L) {
          skipped <- skipped + 1L
          fold_auc[position] <- NA_real_
          next
        }
        prediction <- .fit_predict_probs(
          fit_predict,
          X[train_index, , drop = FALSE],
          binary_y[train_index],
          X[test_index, , drop = FALSE]
        )
        engine <- attr(prediction, "engine")
        if (!is.null(engine)) {
          engines <- c(engines, engine)
        }
        fold_auc[position] <- .auc(test_y, prediction)
      }
    }
    list(fold_auc = fold_auc, skipped = skipped, engines = engines)
  })

  valid_auc <- result$fold_auc[is.finite(result$fold_auc)]
  if (length(valid_auc) == 0L) {
    stop("No fold produced a finite AUC.", call. = FALSE)
  }
  skipped_fraction <- result$skipped / length(result$fold_auc)
  if (skipped_fraction > 0.2) {
    stop(
      "More than 20% of folds were skipped because a class was missing.",
      call. = FALSE
    )
  }
  if (result$skipped > 0L) {
    warning(
      result$skipped,
      " fold(s) were skipped because a class was missing.",
      call. = FALSE
    )
  }

  mean_auc <- mean(valid_auc)
  inverted <- FALSE
  if (mean_auc < 0.5) {
    mean_auc <- 1 - mean_auc
    inverted <- TRUE
    warning(
      "Mean cross-validated AUC was below 0.5; it has been inverted.",
      call. = FALSE
    )
  }
  mean_auc <- min(max(mean_auc, 0), 1)

  apparent_auc <- NA_real_
  corrected_auc <- mean_auc
  if (correction == "optimism") {
    full_prediction <- .fit_predict_probs(fit_predict, X, binary_y, X)
    apparent_auc <- .auc(binary_y, full_prediction)
    if (is.finite(apparent_auc)) {
      corrected_auc <- 0.368 * apparent_auc + 0.632 * mean_auc
    }
    if (corrected_auc < 0.5) {
      corrected_auc <- 1 - corrected_auc
    }
    corrected_auc <- min(max(corrected_auc, 0), 1)
  }

  score <- 2 * corrected_auc - 1
  score <- min(max(score, 0), 1)
  attr(score, "mean_auc") <- corrected_auc
  attr(score, "raw_mean_auc") <- mean_auc
  attr(score, "apparent_auc") <- apparent_auc
  attr(score, "fold_auc") <- valid_auc
  attr(score, "repeats") <- repeats
  attr(score, "folds") <- folds
  attr(score, "skipped") <- result$skipped
  attr(score, "inverted") <- inverted
  attr(score, "correction") <- correction
  attr(score, "engines") <- unique(result$engines)
  score
}
