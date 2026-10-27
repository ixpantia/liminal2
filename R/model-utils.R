#' @keywords internal
.make_design <- function(X, reference_columns = NULL) {
  if (is.matrix(X) && is.numeric(X)) {
    design <- X
    storage.mode(design) <- "double"
    if (is.null(colnames(design))) {
      colnames(design) <- paste0("V", seq_len(ncol(design)))
    }
    design <- cbind("(Intercept)" = 1, design)
  } else {
    data <- as.data.frame(X, stringsAsFactors = FALSE)
    design <- stats::model.matrix(~ ., data = data)
  }
  if (!is.null(reference_columns)) {
    aligned <- matrix(
      0,
      nrow = nrow(design),
      ncol = length(reference_columns),
      dimnames = list(NULL, reference_columns)
    )
    common <- intersect(reference_columns, colnames(design))
    aligned[, common] <- design[, common, drop = FALSE]
    if ("(Intercept)" %in% reference_columns) {
      aligned[, "(Intercept)"] <- 1
    }
    design <- aligned
  }
  design
}

#' @keywords internal
.standardise_design <- function(design) {
  intercept <- rep(1, nrow(design))
  if ("(Intercept)" %in% colnames(design)) {
    non_intercept <- setdiff(colnames(design), "(Intercept)")
  } else {
    non_intercept <- colnames(design)
  }
  if (length(non_intercept) == 0L) {
    return(list(
      x = matrix(intercept, ncol = 1L),
      means = numeric(0),
      sds = numeric(0),
      columns = character(0)
    ))
  }
  values <- design[, non_intercept, drop = FALSE]
  means <- colMeans(values)
  sds <- apply(values, 2L, stats::sd)
  sds[!is.finite(sds) | sds == 0] <- 1
  scaled <- sweep(values, 2L, means, "-")
  scaled <- sweep(scaled, 2L, sds, "/")
  list(
    x = cbind(intercept, scaled),
    means = means,
    sds = sds,
    columns = non_intercept
  )
}

#' @keywords internal
.ridge_logistic_fit <- function(design, y, lambda, initial = NULL,
                                max_iter = 30L, tolerance = 1e-7) {
  standardised <- .standardise_design(design)
  x <- standardised$x
  p <- ncol(x)
  if (is.null(initial) || length(initial) != p) {
    beta <- rep(0, p)
  } else {
    beta <- initial
  }
  penalty <- c(0, rep(1, p - 1L))
  for (iteration in seq_len(max_iter)) {
    eta <- drop(x %*% beta)
    probability <- stats::plogis(eta)
    weight <- pmax(probability * (1 - probability), 1e-8)
    gradient <- drop(crossprod(x, y - probability)) -
      lambda * penalty * beta
    hessian <- crossprod(x, x * weight) +
      lambda * diag(penalty, nrow = p)
    step <- tryCatch(
      solve(hessian, gradient),
      error = function(e) rep(NA_real_, p)
    )
    if (any(!is.finite(step))) {
      step <- tryCatch(
        qr.solve(hessian, gradient),
        error = function(e) rep(0, p)
      )
    }
    if (any(!is.finite(step))) {
      break
    }
    beta_new <- beta + step
    if (max(abs(step)) < tolerance) {
      beta <- beta_new
      break
    }
    beta <- beta_new
  }
  list(
    beta = beta,
    means = standardised$means,
    sds = standardised$sds,
    columns = standardised$columns,
    lambda = lambda,
    engine = "ridge"
  )
}

#' @keywords internal
.predict_ridge <- function(fit, design) {
  if (length(fit$columns) == 0L) {
    return(rep(stats::plogis(fit$beta[1L]), nrow(design)))
  }
  values <- design[, fit$columns, drop = FALSE]
  scaled <- sweep(values, 2L, fit$means, "-")
  scaled <- sweep(scaled, 2L, fit$sds, "/")
  x <- cbind(1, scaled)
  stats::plogis(drop(x %*% fit$beta))
}

#' @keywords internal
.default_fit <- function(X_train, y_train) {
  design_train <- .make_design(X_train)
  fit <- tryCatch(
    suppressWarnings(stats::glm.fit(
      x = design_train,
      y = y_train,
      family = stats::binomial(),
      intercept = FALSE
    )),
    error = function(e) NULL
  )
  separated <- is.null(fit) || !isTRUE(fit$converged) ||
    anyNA(fit$coefficients) ||
    any(abs(fit$coefficients) > 15)
  if (separated) {
    ridge <- .ridge_logistic_fit(design_train, y_train, lambda = 1e-2)
    return(list(
      kind = "ridge",
      fit = ridge,
      columns = colnames(design_train),
      engine = "ridge"
    ))
  }
  list(
    kind = "glm",
    coefficients = fit$coefficients,
    columns = colnames(design_train),
    engine = "glm"
  )
}

#' @keywords internal
.default_predict <- function(fit, X_new) {
  design_new <- .make_design(X_new, fit$columns)
  prediction <- if (fit$kind == "glm") {
    drop(stats::plogis(drop(design_new %*% fit$coefficients)))
  } else {
    .predict_ridge(fit$fit, design_new)
  }
  prediction <- pmin(pmax(prediction, 1e-8), 1 - 1e-8)
  attr(prediction, "engine") <- fit$engine
  prediction
}

#' @keywords internal
.default_fit_predict <- function(X_train, y_train, X_new) {
  .default_predict(.default_fit(X_train, y_train), X_new)
}

#' @keywords internal
.extract_probabilities <- function(prediction, n) {
  if (is.list(prediction) && !is.data.frame(prediction)) {
    if (!is.null(prediction$predictions)) {
      prediction <- prediction$predictions
    } else if (!is.null(prediction$prob)) {
      prediction <- prediction$prob
    } else if (!is.null(prediction$pred)) {
      prediction <- prediction$pred
    }
  }
  if (is.data.frame(prediction) || is.matrix(prediction)) {
    if (ncol(prediction) == 2L) {
      prediction <- prediction[, 2L]
    } else if (ncol(prediction) == 1L) {
      prediction <- prediction[, 1L]
    } else {
      stop("Predicted probabilities must have one or two columns.",
        call. = FALSE
      )
    }
  }
  if (is.factor(prediction) || is.character(prediction)) {
    prediction <- as.numeric(prediction)
  }
  if (!is.numeric(prediction) || length(prediction) != n) {
    stop(
      "`fit_predict` must return one probability per new observation.",
      call. = FALSE
    )
  }
  if (any(!is.finite(prediction)) ||
    any(prediction < 0 | prediction > 1)) {
    stop("Predicted probabilities must be finite values in [0, 1].",
      call. = FALSE
    )
  }
  prediction
}

#' @keywords internal
.fit_predict_pair <- function(fit_predict, X_train, y_train, X_new,
                              X_second) {
  if (is.null(fit_predict)) {
    fit <- .default_fit(X_train, y_train)
    return(list(
      first = .default_predict(fit, X_new),
      second = .default_predict(fit, X_second)
    ))
  }
  if (is.list(fit_predict) && !is.function(fit_predict)) {
    if (!is.function(fit_predict$fit) || !is.function(fit_predict$predict)) {
      stop(
        "`fit_predict` must be a function or a list with `fit` and ",
        "`predict` functions.",
        call. = FALSE
      )
    }
    model <- fit_predict$fit(X_train, y_train)
    first <- .extract_probabilities(
      fit_predict$predict(model, X_new),
      nrow(X_new)
    )
    second <- .extract_probabilities(
      fit_predict$predict(model, X_second),
      nrow(X_second)
    )
    return(list(first = first, second = second))
  }
  list(
    first = .fit_predict_probs(fit_predict, X_train, y_train, X_new),
    second = .fit_predict_probs(fit_predict, X_train, y_train, X_second)
  )
}

#' @keywords internal
.fit_predict_probs <- function(fit_predict, X_train, y_train, X_new) {
  if (is.null(fit_predict)) {
    return(.default_fit_predict(X_train, y_train, X_new))
  }
  if (is.list(fit_predict) && !is.function(fit_predict)) {
    if (!is.function(fit_predict$fit) || !is.function(fit_predict$predict)) {
      stop(
        "`fit_predict` must be a function or a list with `fit` and ",
        "`predict` functions.",
        call. = FALSE
      )
    }
    model <- fit_predict$fit(X_train, y_train)
    prediction <- fit_predict$predict(model, X_new)
    return(.extract_probabilities(prediction, nrow(X_new)))
  }
  if (!is.function(fit_predict)) {
    stop("`fit_predict` must be a function or a list.", call. = FALSE)
  }
  prediction <- tryCatch(
    fit_predict(X_train, y_train, X_new),
    error = function(e) e
  )
  if (inherits(prediction, "error")) {
    model <- fit_predict(X_train, y_train)
    prediction <- tryCatch(
      stats::predict(model, newdata = X_new, type = "response"),
      error = function(e) NULL
    )
    if (is.null(prediction)) {
      stop(
        "`fit_predict` could not be applied. It must accept ",
        "`(X_train, y_train, X_new)` and return probabilities.",
        call. = FALSE
      )
    }
  }
  .extract_probabilities(prediction, nrow(X_new))
}

#' @keywords internal
.auc <- function(y, probability) {
  y <- as.integer(y)
  probability <- as.numeric(probability)
  cases <- y == 1L
  controls <- y == 0L
  n_cases <- sum(cases)
  n_controls <- sum(controls)
  if (n_cases == 0L || n_controls == 0L) {
    return(NA_real_)
  }
  ranks <- rank(probability, ties.method = "average")
  (sum(ranks[cases]) - n_cases * (n_cases + 1) / 2) /
    (n_cases * n_controls)
}

#' @keywords internal
.binary_metric <- function(y, probability) {
  auc <- .auc(y, probability)
  if (is.finite(auc)) {
    return(auc)
  }
  prediction <- as.integer(probability >= 0.5)
  mean(prediction == y)
}

#' @keywords internal
.stratified_fold_id <- function(y, folds) {
  fold_id <- integer(length(y))
  for (class in sort(unique(y))) {
    index <- which(y == class)
    index <- index[sample.int(length(index))]
    fold_id[index] <- rep(seq_len(folds), length.out = length(index))
  }
  fold_id
}

#' @keywords internal
.ridge_logistic_path <- function(design, y, n_lambda = 25L) {
  n_lambda <- max(2L, as.integer(n_lambda))
  lambdas <- exp(seq(log(5), log(1e-4), length.out = n_lambda))
  fits <- vector("list", length(lambdas))
  initial <- NULL
  for (index in seq_along(lambdas)) {
    fit <- .ridge_logistic_fit(
      design,
      y,
      lambda = lambdas[index],
      initial = initial
    )
    fits[[index]] <- fit
    initial <- fit$beta
  }
  fits
}
