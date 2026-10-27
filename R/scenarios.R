#' @keywords internal
.scenario_specs <- function() {
  list(
    S1 = list(
      id = "S1",
      title = "Invoice-to-PO matching",
      n = 20000L,
      p = 8L,
      rival_definitions = 2L,
      a1 = 0.98, a2 = 0.97, a3 = 0.95,
      a4 = 0.95, a5 = 0.95, a6 = 0.90,
      target_A = 0.951, target_L = 0.049,
      signal_features = 3L,
      component_args = list(
        a3 = list(variant = "penalty", eps = 0.02, B = 30),
        a4 = list(folds = 5, repeats = 3)
      ),
      notes = "Rule-adjudicated finance operations with no material drift."
    ),
    S2 = list(
      id = "S2",
      title = "Regulated loan default",
      n = 15000L,
      p = 20L,
      rival_definitions = 2L,
      a1 = 0.90, a2 = 0.80, a3 = 0.75,
      a4 = 0.60, a5 = 0.85, a6 = 0.80,
      target_A = 0.773, target_L = 0.227,
      signal_features = 4L,
      component_args = list(
        a3 = list(variant = "penalty", eps = 0.02, B = 30),
        a4 = list(folds = 5, repeats = 3)
      ),
      notes = "Institutionalised external definition with modest drift."
    ),
    S3 = list(
      id = "S3",
      title = "Subscription churn",
      n = 25000L,
      p = 30L,
      rival_definitions = 4L,
      a1 = 0.55, a2 = 0.60, a3 = 0.55,
      a4 = 0.60, a5 = 0.30, a6 = 0.40,
      target_A = 0.493, target_L = 0.507,
      signal_features = 5L,
      component_args = list(
        a3 = list(variant = "penalty", eps = 0.02, B = 30),
        a4 = list(folds = 5, repeats = 3)
      ),
      notes = "Partial-churn ambiguity with a mid-timeline regime shift."
    ),
    S4 = list(
      id = "S4",
      title = "Employee attrition",
      n = 8000L,
      p = 40L,
      rival_definitions = 5L,
      a1 = 0.40, a2 = 0.55, a3 = 0.45,
      a4 = 0.35, a5 = 0.20, a6 = 0.25,
      target_A = 0.349, target_L = 0.651,
      signal_features = 6L,
      component_args = list(
        a3 = list(variant = "subsample", eps = 0.02, B = 80),
        a4 = list(folds = 5, repeats = 3)
      ),
      notes = "Flight-risk scoring without voluntary/involuntary separation."
    ),
    S5 = list(
      id = "S5",
      title = "Causal long-run LTV",
      n = 5000L,
      p = 15L,
      rival_definitions = 3L,
      a1 = 0.20, a2 = 0.30, a3 = 0.20,
      a4 = 0.12, a5 = 0.03, a6 = 0.10,
      target_A = 0.120, target_L = 0.880,
      signal_features = 4L,
      component_args = list(
        a3 = list(variant = "bootstrap", eps = 0.02, B = 120),
        a4 = list(folds = 5, repeats = 3)
      ),
      notes = "Counterfactual LTV with an unmeasured price confounder."
    )
  )
}

#' Scenario registry
#'
#' Returns the five benchmark scenarios, their targets and their default
#' component settings.
#'
#' @return A data.frame of scenario metadata.
#' @export
#' @examples
#' scenario_registry()
scenario_registry <- function() {
  specs <- .scenario_specs()
  data.frame(
    id = vapply(specs, `[[`, character(1), "id"),
    title = vapply(specs, `[[`, character(1), "title"),
    n = vapply(specs, `[[`, integer(1), "n"),
    p = vapply(specs, `[[`, integer(1), "p"),
    rival_definitions =
      vapply(specs, `[[`, integer(1), "rival_definitions"),
    a1 = vapply(specs, `[[`, numeric(1), "a1"),
    a2 = vapply(specs, `[[`, numeric(1), "a2"),
    a3 = vapply(specs, `[[`, numeric(1), "a3"),
    a4 = vapply(specs, `[[`, numeric(1), "a4"),
    a5 = vapply(specs, `[[`, numeric(1), "a5"),
    a6 = vapply(specs, `[[`, numeric(1), "a6"),
    target_A = vapply(specs, `[[`, numeric(1), "target_A"),
    target_L = vapply(specs, `[[`, numeric(1), "target_L"),
    notes = vapply(specs, `[[`, character(1), "notes"),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' @keywords internal
.anchor_scores <- function(target, rubric) {
  units <- max(0L, min(24L, as.integer(round(target * 24))))
  item_units <- integer(6L)
  remaining <- units
  for (index in seq_len(6L)) {
    item_units[index] <- min(4L, remaining)
    remaining <- remaining - item_units[index]
  }
  scores <- item_units / 4
  names(scores) <- .rubric_items(rubric)
  scores
}

#' @keywords internal
.make_rival_labels <- function(y, target_alpha, rival_definitions) {
  n <- length(y)
  if (target_alpha >= 0.9999) {
    return(as.data.frame(
      matrix(y, nrow = n, ncol = rival_definitions)
    ))
  }
  uniforms <- matrix(
    stats::runif(n * rival_definitions),
    nrow = n,
    ncol = rival_definitions
  )
  alpha_at <- function(error) {
    definitions <- matrix(y, nrow = n, ncol = rival_definitions)
    flip <- uniforms < error
    definitions[flip] <- 1 - definitions[flip]
    value <- tryCatch(
      .kripp_alpha_nominal(
        as.data.frame(definitions)
      ),
      error = function(e) -1
    )
    value
  }
  lower_value <- alpha_at(0)
  upper_value <- alpha_at(0.5)
  if (target_alpha >= lower_value) {
    error <- 0
  } else if (target_alpha <= upper_value) {
    error <- 0.5
  } else {
    error <- tryCatch(
      stats::uniroot(
        function(value) alpha_at(value) - target_alpha,
        interval = c(0, 0.5),
        tol = 1e-7
      )$root,
      error = function(e) 0.1
    )
  }
  definitions <- matrix(y, nrow = n, ncol = rival_definitions)
  flip <- uniforms < error
  definitions[flip] <- 1 - definitions[flip]
  output <- as.data.frame(definitions)
  names(output) <- paste0("definition_", seq_len(rival_definitions))
  output
}

#' @keywords internal
.auc_scale_table <- function() {
  data.frame(
    auc = c(
      0.54460, 0.58811, 0.62981, 0.70475, 0.76556, 0.81391,
      0.86533, 0.90027, 0.93560, 0.95577, 0.96801, 0.97588,
      0.98129, 0.98778
    ),
    scale = c(
      0.10, 0.20, 0.30, 0.50, 0.70, 0.90,
      1.20, 1.50, 2.00, 2.50, 3.00, 3.50,
      4.00, 5.00
    )
  )
}

#' @keywords internal
.scale_for_auc <- function(target_auc) {
  if (!is.finite(target_auc) || target_auc <= 0.5) {
    return(0)
  }
  table <- .auc_scale_table()
  if (target_auc >= max(table$auc)) {
    return(max(table$scale))
  }
  interpolator <- stats::splinefun(
    table$auc,
    table$scale,
    method = "monoH.FC"
  )
  as.numeric(interpolator(target_auc))
}

#' @keywords internal
.calibrate_drift <- function(base, time_index, profile, target_a2) {
  if (target_a2 >= 0.9999) {
    return(0)
  }
  lambda <- log(2) / 0.25
  target_drift <- -log(target_a2) / lambda
  drift_at <- function(slope) {
    X <- as.data.frame(base + slope * profile)
    value <- temporal_stability(X, time_index, k = 4, bins = 10)
    attr(value, "drift")
  }
  upper <- 1
  upper_drift <- drift_at(upper)
  while (upper_drift < target_drift && upper < 1e6) {
    upper <- upper * 2
    upper_drift <- drift_at(upper)
  }
  if (upper_drift < target_drift) {
    return(upper)
  }
  stats::uniroot(
    function(slope) drift_at(slope) - target_drift,
    interval = c(0, upper),
    tol = 1e-5
  )$root
}

#' @keywords internal
.make_scenario_data <- function(spec) {
  n <- spec$n
  p <- spec$p
  time_index <- seq_len(n)
  base <- matrix(
    stats::rnorm(n * p),
    nrow = n,
    ncol = p,
    dimnames = list(NULL, paste0("feature_", seq_len(p)))
  )
  time_scaled <- (time_index - 1) / max(1, n - 1)
  if (spec$id == "S3") {
    profile <- as.numeric(time_scaled >= 0.6)
  } else {
    profile <- time_scaled
  }
  slope <- .calibrate_drift(base, time_index, profile, spec$a2)
  X <- as.data.frame(base + slope * profile)
  signal <- rowMeans(scale(
    as.matrix(X[, seq_len(spec$signal_features), drop = FALSE])
  ))
  signal_sd <- stats::sd(signal)
  if (!is.finite(signal_sd) || signal_sd == 0) {
    signal_sd <- 1
  }
  bayes_auc <- (spec$a4 + 1) / 2
  signal_scale <- .scale_for_auc(bayes_auc)
  eta <- signal_scale * signal / signal_sd
  y <- as.integer(eta + stats::rnorm(n) > 0)
  if (length(unique(y)) < 2L) {
    y[seq_len(max(2L, floor(n * 0.1)))] <- c(0L, 1L)
  }
  list(
    X = X,
    y = y,
    time_index = time_index,
    bayes_auc = bayes_auc
  )
}

#' Generate a benchmark scenario
#'
#' Generates one of the five deterministic benchmark scenarios. The variants
#' used by the audit tests are available through the `variant` argument or
#' by appending a suffix to `id` (`S3_leak`, `S1_null`, `S4_shuffled`).
#'
#' @section S5 proxy:
#' The S5 target is a counterfactual, so `a4` is a documented proxy computed
#' over observed outcomes with a Bayes AUC of 0.56. The proxy state is
#' recorded in `truth$identifiability`; all other scenarios are observed.
#'
#' @section Authored component targets:
#' The scenario component table is an authored typology. Because binary
#' Rashomon ambiguity has a floor of 0.5, the S4 and S5 `a3` targets are
#' below the estimator's attainable range. The benchmark therefore checks
#' recovery, ordering and auditing of the composite `L`.
#'
#' @param id Scenario id (`"S1"` to `"S5"`), optionally with a variant
#'   suffix.
#' @param seed Integer seed.
#' @param variant `"base"`, `"leak"`, `"null"` or `"shuffled"`.
#'
#' @return A list with `X`, `y`, `time_index`, `label_defs`, `rubric`,
#'   `truth` and `metadata`.
#' @export
#' @examples
#' \donttest{
#' scenario <- generate_scenario("S5", seed = 42)
#' names(scenario)
#' }
generate_scenario <- function(id, seed = 42L, variant = "base") {
  if (!is.character(id) || length(id) != 1L) {
    stop("`id` must be a single scenario id.", call. = FALSE)
  }
  requested <- toupper(id)
  if (grepl("_", requested)) {
    suffix <- sub("^.*_", "", requested)
    requested <- sub("_.*$", "", requested)
    variant <- switch(tolower(suffix),
      leak = "leak",
      null = "null",
      shuffled = "shuffled",
      suffix
    )
  }
  variant <- match.arg(variant, c("base", "leak", "null", "shuffled"))
  specs <- .scenario_specs()
  if (!requested %in% names(specs)) {
    stop(
      "`id` must be one of: ", paste(names(specs), collapse = ", "), ".",
      call. = FALSE
    )
  }
  if (is.null(seed)) {
    stop("`seed` must be supplied for deterministic scenario generation.",
      call. = FALSE
    )
  }
  .check_seed(seed)
  spec <- specs[[requested]]
  data <- .run_seeded(seed, function() {
    .make_scenario_data(spec)
  })
  X <- data$X
  y <- data$y
  label_defs <- .run_seeded(seed + 1L, function() {
    .make_rival_labels(y, spec$a1, spec$rival_definitions)
  })
  if (variant == "leak") {
    X$label_leak <- y + stats::rnorm(nrow(X), sd = 0.01)
  } else if (variant == "null") {
    y <- .run_seeded(seed + 2L, function() sample(y))
  } else if (variant == "shuffled") {
    X <- .run_seeded(seed + 3L, function() {
      as.data.frame(lapply(X, sample))
    })
    names(X) <- names(data$X)
  }
  oracle_scores <- .anchor_scores(spec$a5, "oracle")
  normative_scores <- .anchor_scores(spec$a6, "normative")
  target_components <- c(
    a1 = spec$a1, a2 = spec$a2, a3 = spec$a3,
    a4 = spec$a4, a5 = spec$a5, a6 = spec$a6
  )
  truth <- list(
    id = requested,
    title = spec$title,
    target_components = target_components,
    target_A = spec$target_A,
    target_L = spec$target_L,
    bayes_auc = data$bayes_auc,
    rubric_components = c(
      a5 = mean(oracle_scores),
      a6 = mean(normative_scores)
    ),
    component_args = spec$component_args,
    identifiability = if (requested == "S5") "proxy" else "observed",
    notes = spec$notes
  )
  list(
    X = X,
    y = y,
    time_index = data$time_index,
    label_defs = label_defs,
    rubric = list(
      oracle = oracle_scores,
      normative = normative_scores
    ),
    truth = truth,
    metadata = list(
      id = requested,
      variant = variant,
      seed = seed,
      n = nrow(X),
      p = ncol(X)
    )
  )
}
