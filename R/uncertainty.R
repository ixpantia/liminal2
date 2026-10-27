#' Bootstrap a liminality assessment
#'
#' Resamples units for `a1` to `a4` and resamples or perturbs expert scores
#' for `a5` and `a6`, then recomputes the assessment. Percentile intervals
#' are returned for `A`, `L` and every component.
#'
#' @param fit A `liminality_assessment` produced by [assess_goal()] with raw
#'   component inputs.
#' @param B Number of bootstrap resamples.
#' @param seed Optional integer seed. The caller's random-number state is
#'   restored on exit.
#' @param conf_level Confidence level for the percentile interval.
#'
#' @return An object of class `liminality_bootstrap`.
#' @export
#' @examples
#' \donttest{
#' set.seed(1)
#' X <- data.frame(x = rnorm(300))
#' y <- as.integer(X$x + rnorm(300) > 0)
#' defs <- data.frame(
#'   first = y,
#'   second = y
#' )
#' oracle <- c(
#'   external_authority = 1, codified_definition = 1,
#'   timeliness = 0.75, model_independence = 1,
#'   inter_judge_agreement = 0.75, ex_post_detectability = 1
#' )
#' normative <- c(
#'   threshold_owner = 0.75, cost_ratio_agreed = 0.5,
#'   stakeholder_agreement = 0.75, regulatory_constraint = 0.5,
#'   reversibility = 0.75, precedent = 0.5
#' )
#' goal <- assess_goal(
#'   label_defs = defs, X = X, time_index = seq_len(300), y = y,
#'   oracle_scores = oracle, normative_scores = normative,
#'   component_args = list(
#'     a3 = list(variant = "subsample", B = 10),
#'     a4 = list(repeats = 2)
#'   )
#' )
#' bootstrap_liminality(goal, B = 5, seed = 42)
#' }
bootstrap_liminality <- function(fit, B = 2000, seed = NULL,
                                 conf_level = 0.95) {
  if (!inherits(fit, "liminality_assessment")) {
    stop("`fit` must be a liminality_assessment.", call. = FALSE)
  }
  if (is.null(fit$recompute) || !is.function(fit$recompute)) {
    stop(
      "`fit` does not contain raw component inputs. Use assess_goal() ",
      "with data inputs before bootstrapping.",
      call. = FALSE
    )
  }
  B <- .check_positive_integer(B, "B", minimum = 2L)
  .check_prob(conf_level, "conf_level")
  if (is.null(fit$n_units) || !is.finite(fit$n_units) ||
    fit$n_units < 2L) {
    stop("Bootstrap resampling requires at least two units.",
      call. = FALSE
    )
  }
  n_units <- as.integer(fit$n_units)
  draws <- .run_seeded(seed, function() {
    result <- matrix(
      NA_real_,
      nrow = B,
      ncol = 6L,
      dimnames = list(NULL, .component_names())
    )
    for (iteration in seq_len(B)) {
      index <- sample.int(n_units, n_units, replace = TRUE)
      value <- tryCatch(
        fit$recompute(index),
        error = function(e) NULL
      )
      if (!is.null(value) && length(value) == 6L &&
        all(is.finite(value))) {
        result[iteration, ] <- as.numeric(value)
      }
    }
    result
  })
  valid <- stats::complete.cases(draws)
  required <- min(B, max(3L, ceiling(0.5 * B)))
  if (sum(valid) < required) {
    stop("Too few bootstrap resamples produced finite components.",
      call. = FALSE
    )
  }
  draws <- draws[valid, , drop = FALSE]
  A_draws <- apply(draws, 1L, function(value) {
    if (fit$method == "arithmetic") {
      .arithmetic_composite(value, fit$weights)
    } else {
      .geometric_composite(value, fit$weights)
    }
  })
  output <- data.frame(
    draws,
    A = A_draws,
    L = 1 - A_draws,
    check.names = FALSE
  )
  alpha <- (1 - conf_level) / 2
  probability <- c(alpha, 1 - alpha)
  rows <- c("A", "L", .component_names())
  interval <- t(vapply(
    rows,
    function(name) {
      stats::quantile(
        output[[name]],
        probs = probability,
        names = FALSE,
        na.rm = TRUE
      )
    },
    numeric(2)
  ))
  colnames(interval) <- c("lower", "upper")
  result <- list(
    estimate = c(A = fit$A, L = fit$L, fit$components),
    ci = interval,
    draws = output,
    B = B,
    n_valid = nrow(draws),
    seed = seed,
    conf_level = conf_level
  )
  class(result) <- "liminality_bootstrap"
  result
}

#' @keywords internal
.as_goal_list <- function(a) {
  if (inherits(a, "liminality_assessment")) {
    return(list(components = a$components))
  }
  if (is.numeric(a) && !is.null(names(a))) {
    if (!setequal(names(a), .component_names())) {
      stop("Component vectors must contain a1 to a6.", call. = FALSE)
    }
    return(list(components = a[.component_names()]))
  }
  if (is.list(a) && !is.data.frame(a)) {
    goals <- lapply(a, function(goal) {
      if (inherits(goal, "liminality_assessment")) {
        return(goal$components)
      }
      if (is.numeric(goal) && !is.null(names(goal)) &&
        setequal(names(goal), .component_names())) {
        return(goal[.component_names()])
      }
      stop("Every goal must contain components a1 to a6.",
        call. = FALSE
      )
    })
    return(list(components = goals))
  }
  if (is.matrix(a) && is.numeric(a) &&
    ncol(a) == length(.component_names())) {
    if (is.null(colnames(a))) {
      colnames(a) <- .component_names()
    }
    if (!setequal(colnames(a), .component_names())) {
      stop("Component matrix columns must be a1 to a6.",
        call. = FALSE
      )
    }
    goals <- lapply(seq_len(nrow(a)), function(row) {
      a[row, .component_names()]
    })
    return(list(components = goals))
  }
  stop("`a` must be an assessment, a component vector or a list of goals.",
    call. = FALSE
  )
}

#' Weight sensitivity
#'
#' Draws weights from a Dirichlet distribution over the component simplex
#' and recomputes liminality. With two goals, the fraction of draws that
#' preserve their liminality ranking is reported.
#'
#' @param a A `liminality_assessment`, a named component vector, or a list
#'   of two component vectors.
#' @param n Number of Dirichlet draws.
#' @param prior Positive Dirichlet concentration parameters, named or
#'   positional over `a1` to `a6`.
#' @param seed Optional integer seed. The caller's random-number state is
#'   restored on exit.
#'
#' @return An object of class `liminality_sensitivity`.
#' @export
#' @examples
#' a <- c(
#'   a1 = 0.9, a2 = 0.8, a3 = 0.7,
#'   a4 = 0.6, a5 = 0.5, a6 = 0.4
#' )
#' weight_sensitivity(a, n = 100, seed = 42)
weight_sensitivity <- function(a, n = 1000, prior = NULL, seed = NULL) {
  goals <- .as_goal_list(a)$components
  single_goal <- is.numeric(goals)
  if (single_goal) {
    goals <- list(goals)
  }
  if (!is.list(goals) || length(goals) < 1L) {
    stop("`a` must contain at least one goal.", call. = FALSE)
  }
  goals <- lapply(goals, function(goal) {
    .check_prob_vector(goal, "a")
    goal[.component_names()]
  })
  if (length(goals) > 2L) {
    stop("Ranking preservation is defined for at most two goals.",
      call. = FALSE
    )
  }
  n <- .check_positive_integer(n, "n", minimum = 2L)
  if (is.null(prior)) {
    prior <- rep(1, length(.component_names()))
    names(prior) <- .component_names()
  } else {
    if (!is.numeric(prior) || any(!is.finite(prior)) || any(prior <= 0)) {
      stop("`prior` must contain positive finite values.", call. = FALSE)
    }
    if (is.null(names(prior))) {
      if (length(prior) != length(.component_names())) {
        stop("Unnamed `prior` must have length six.", call. = FALSE)
      }
      names(prior) <- .component_names()
    } else {
      if (!setequal(names(prior), .component_names())) {
        stop("Named `prior` must contain a1 to a6.", call. = FALSE)
      }
      prior <- prior[.component_names()]
    }
  }
  draws <- .run_seeded(seed, function() {
    raw <- matrix(
      stats::rgamma(n * length(prior), shape = prior),
      nrow = n,
      byrow = TRUE
    )
    raw / rowSums(raw)
  })
  colnames(draws) <- .component_names()
  L_draws <- vapply(
    seq_len(nrow(draws)),
    function(row) {
      weights <- draws[row, ]
      1 - .geometric_composite(goals[[1L]], weights)
    },
    numeric(1)
  )
  probs <- c(0.025, 0.25, 0.5, 0.75, 0.975)
  result <- list(
    n = n,
    prior = prior,
    weights = draws,
    L_draws = L_draws,
    L_quantiles = stats::quantile(
      L_draws,
      probs = probs,
      names = TRUE
    ),
    A_quantiles = stats::quantile(
      1 - L_draws,
      probs = probs,
      names = TRUE
    ),
    ranking_fraction = NULL,
    probability_goal1_more_liminal = NULL,
    seed = seed
  )
  if (length(goals) == 2L) {
    L_second <- vapply(
      seq_len(nrow(draws)),
      function(row) {
        weights <- draws[row, ]
        1 - .geometric_composite(goals[[2L]], weights)
      },
      numeric(1)
    )
    result$L_second_draws <- L_second
    result$ranking_fraction <- mean(L_draws < L_second)
    result$probability_goal1_more_liminal <- mean(L_draws > L_second)
    result$goals <- goals
  }
  class(result) <- "liminality_sensitivity"
  result
}
