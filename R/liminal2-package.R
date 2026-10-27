#' liminal2: Estimating the Size of the Liminal Space
#'
#' `liminal2` estimates adjudication strength and liminality for predictive
#' modelling goals. The package provides base-R estimators for six
#' components, bootstrap uncertainty, weight sensitivity, leakage audits and
#' five benchmark scenarios.
#'
#' @section Design decisions:
#' * Components `a5` and `a6` are supplied as anchored rubric score vectors;
#'   the package does not ship an interactive elicitation interface.
#' * Scenario S5 estimates `a4` with a documented observed-outcome proxy
#'   because its target is counterfactual.
#' * The estimators use base R; suggested packages are only used for tests,
#'   cross-checks and development.
#'
#' @importFrom methods is
#' @keywords internal
"_PACKAGE"
