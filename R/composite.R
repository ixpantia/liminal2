#' @keywords internal
.geometric_composite <- function(a, w) {
  terms <- ifelse(w == 0, 1, a^w)
  prod(terms)
}

#' @keywords internal
.arithmetic_composite <- function(a, w) {
  sum(w * a)
}

#' Liminality assessment from components
#'
#' Combines the six components into adjudication strength `A` and
#' liminality `L = 1 - A`. The canonical composite is geometric.
#'
#' @param a A named numeric vector with components `a1` to `a6`, each in
#'   unit interval.
#' @param w Named component weights summing to one.
#' @param method `"geometric"`, `"arithmetic"` or `"both"`. With
#'   `"both"`, `A` is the geometric composite and the arithmetic value is
#'   stored separately.
#'
#' @return An object of class `liminality_assessment`.
#' @export
#' @examples
#' a <- c(
#'   a1 = 0.9, a2 = 0.8, a3 = 0.7,
#'   a4 = 0.6, a5 = 0.5, a6 = 0.4
#' )
#' liminality(a)
liminality <- function(a,
                       w = default_weights(),
                       method = c("geometric", "arithmetic", "both")) {
  method <- match.arg(method)
  if (!is.numeric(a) || is.null(names(a))) {
    stop("`a` must be a named numeric vector.", call. = FALSE)
  }
  if (anyDuplicated(names(a))) {
    stop("`a` must not contain duplicated names.", call. = FALSE)
  }
  if (!setequal(names(a), .component_names())) {
    stop(
      "`a` must be named exactly: a1, a2, a3, a4, a5, a6.",
      call. = FALSE
    )
  }
  a <- a[.component_names()]
  .check_prob_vector(a, "a")
  w <- .check_weights(w)
  a_geometric <- .geometric_composite(a, w)
  a_arithmetic <- .arithmetic_composite(a, w)
  strength <- if (method == "arithmetic") {
    a_arithmetic
  } else {
    a_geometric
  }
  strength <- .clamp_warn(strength, "adjudication strength A")
  dimensions <- .dimension_summary(a)
  assessment <- list(
    A = strength,
    L = 1 - strength,
    components = a,
    weights = w,
    dimensions = dimensions$values,
    dominant_dimension = dimensions$dominant,
    unbounded = dimensions$unbounded,
    method = method,
    A_geometric = a_geometric,
    A_arithmetic = a_arithmetic,
    ci = NULL,
    bootstrap = NULL,
    provenance = NULL,
    call = match.call()
  )
  assessment$provenance <- .provenance(
    args = list(w = w, method = method),
    data = a,
    seed = NULL,
    call = match.call()
  )
  class(assessment) <- "liminality_assessment"
  assessment
}

#' Assess a liminality goal
#'
#' Computes components from data and elicitation inputs, or combines a
#' supplied component vector. Raw component inputs are retained so that
#' [bootstrap_liminality()] can resample units and expert scores.
#'
#' @param a Optional named component vector. When supplied, all data inputs
#'   are ignored.
#' @param w Named component weights summing to one.
#' @param method Composite method, see [liminality()].
#' @param n_boot Number of bootstrap resamples. Zero skips the bootstrap.
#' @param seed Optional integer seed.
#' @param label_defs Rival label definitions for `a1`.
#' @param X Feature data for `a2`, `a3` and `a4`.
#' @param time_index Time index for `a2`.
#' @param y Binary outcome for `a3` and `a4`.
#' @param fit_predict Optional model adapter for `a3` and `a4`.
#' @param oracle_scores Anchored scores for `a5`. A vector gives one expert,
#'   a matrix or data.frame gives one row per expert.
#' @param normative_scores Anchored scores for `a6`.
#' @param component_args Optional named list of extra arguments for the
#'   component functions, for example `list(a4 = list(repeats = 2))`.
#' @param conf_level Confidence level for the bootstrap interval.
#'
#' @return An object of class `liminality_assessment`.
#' @export
#' @examples
#' assess_goal(
#'   a = c(
#'     a1 = 0.9, a2 = 0.8, a3 = 0.7,
#'     a4 = 0.6, a5 = 0.5, a6 = 0.4
#'   )
#' )
assess_goal <- function(a = NULL,
                        w = default_weights(),
                        method = c("geometric", "arithmetic", "both"),
                        n_boot = 0,
                        seed = NULL,
                        label_defs = NULL,
                        X = NULL,
                        time_index = NULL,
                        y = NULL,
                        fit_predict = NULL,
                        oracle_scores = NULL,
                        normative_scores = NULL,
                        component_args = list(),
                        conf_level = 0.95) {
  method <- match.arg(method)
  .check_positive_integer(n_boot, "n_boot", minimum = 0L)
  .check_prob(conf_level, "conf_level")
  if (!is.list(component_args)) {
    stop("`component_args` must be a list.", call. = FALSE)
  }

  recompute <- NULL
  data_inputs <- NULL
  if (is.null(a)) {
    required <- c(
      label_defs = !is.null(label_defs),
      X = !is.null(X),
      time_index = !is.null(time_index),
      y = !is.null(y),
      oracle_scores = !is.null(oracle_scores),
      normative_scores = !is.null(normative_scores)
    )
    if (!all(required)) {
      stop(
        "When `a` is NULL, `label_defs`, `X`, `time_index`, `y`, ",
        "`oracle_scores` and `normative_scores` are required.",
        call. = FALSE
      )
    }
    n_units <- nrow(label_defs)
    if (nrow(X) != n_units || length(y) != n_units ||
      length(time_index) != n_units) {
      stop("All component inputs must have the same number of units.",
        call. = FALSE
      )
    }
    defaults <- list(
      a1 = list(n_boot = 0, seed = NULL),
      a2 = list(),
      a3 = list(seed = NULL),
      a4 = list(seed = NULL)
    )
    args <- lapply(names(defaults), function(name) {
      supplied <- component_args[[name]]
      if (is.null(supplied)) {
        defaults[[name]]
      } else {
        utils::modifyList(defaults[[name]], supplied)
      }
    })
    names(args) <- names(defaults)

    compute_components <- function(index = NULL,
                                   resample_experts = FALSE) {
      if (is.null(index)) {
        index <- seq_len(n_units)
      }
      a1 <- do.call(
        label_determinacy,
        c(list(defs = label_defs[index, , drop = FALSE]), args$a1)
      )
      a2 <- do.call(
        temporal_stability,
        c(
          list(
            X = X[index, , drop = FALSE],
            time_index = time_index[index]
          ),
          args$a2
        )
      )
      a3 <- do.call(
        predictive_multiplicity,
        c(
          list(
            X = X[index, , drop = FALSE],
            y = y[index],
            fit_predict = fit_predict
          ),
          args$a3
        )
      )
      a4 <- do.call(
        discriminability,
        c(
          list(
            X = X[index, , drop = FALSE],
            y = y[index],
            fit_predict = fit_predict
          ),
          args$a4
        )
      )
      a5 <- .rubric_mean(
        oracle_scores,
        rubric = "oracle",
        resample = resample_experts
      )
      a6 <- .rubric_mean(
        normative_scores,
        rubric = "normative",
        resample = resample_experts
      )
      c(a1 = as.numeric(a1), a2 = as.numeric(a2),
        a3 = as.numeric(a3), a4 = as.numeric(a4),
        a5 = a5, a6 = a6
      )
    }

    a <- .run_seeded(seed, function() compute_components())
    a <- vapply(a, as.numeric, numeric(1))
    recompute <- function(index = NULL) {
      compute_components(index = index, resample_experts = TRUE)
    }
    data_inputs <- list(
      label_defs = label_defs,
      X = X,
      time_index = time_index,
      y = y,
      oracle_scores = oracle_scores,
      normative_scores = normative_scores
    )
  } else {
    if (n_boot > 0L) {
      stop(
        "`n_boot` requires raw component inputs, not a precomputed `a`.",
        call. = FALSE
      )
    }
  }

  assessment <- liminality(a, w = w, method = method)
  assessment$provenance <- .provenance(
    args = list(
      w = w,
      method = method,
      n_boot = n_boot,
      seed = seed,
      component_args = component_args
    ),
    data = if (is.null(data_inputs)) a else data_inputs,
    seed = seed,
    call = match.call()
  )
  assessment$recompute <- recompute
  assessment$n_units <- if (is.null(data_inputs)) {
    NA_integer_
  } else {
    nrow(data_inputs$X)
  }
  if (n_boot > 0L) {
    boot <- bootstrap_liminality(
      assessment,
      B = n_boot,
      seed = seed,
      conf_level = conf_level
    )
    assessment$bootstrap <- boot
    assessment$ci <- boot$ci
  }
  assessment
}
