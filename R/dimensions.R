# The canonical dimension registry -------------------------------------
#
# The seven dimensions of liminal space, in canonical order. The order
# is part of the package contract: raw scores, condition scores,
# weights and prompt versions are all reported in this order. Names,
# titles, formal names, questions and evidence come from README
# Table 2; the anchors live in the prompt templates under
# inst/prompts/.

# Canonical order of the seven liminal-space dimensions.
liminal_dimension_names <- c(
  "shared_meaning",
  "stable_ground",
  "convergent_answers",
  "knowable_from_observables",
  "judgeable",
  "action_identifiable",
  "tradeoff_agreed"
)

# Internal registry of dimension metadata. `prompt_version` must be
# bumped whenever the wording or the anchors of the corresponding
# template in inst/prompts/ change, because scores are only comparable
# within one prompt version.
liminal_dimension_registry <- tibble::tibble(
  name = liminal_dimension_names,
  title = c(
    "Shared meaning",
    "Stable ground",
    "Convergent answers",
    "Knowable from what we can see",
    "Judgeable",
    "Action is identifiable",
    "Trade-off is agreed"
  ),
  formal_name = c(
    "Rival operationalisations of the target agree",
    "Outcome-generating process is stable",
    paste(
      "Near-equally-good solutions agree on decisions",
      "(inverted from source)"
    ),
    "Target is attainable from observable features",
    "An external authority can adjudicate",
    "The decision rule is recoverable from the ask",
    "The recovered decision rule is normatively settled"
  ),
  question_business = c(
    paste(
      "When we say \"churned\" or \"risky\", do we all mean",
      "the same customers?"
    ),
    "Will next quarter behave like the last ones?",
    paste(
      "If two good analysts attack this, will they",
      "recommend the same action?"
    ),
    "Is the answer visible in anything we can observe?",
    "Who can say, independently, that this worked?",
    "What will we do differently when we see the output?",
    "Do the people who bear the cost of errors accept this threshold?"
  ),
  question_data_scientist = c(
    "Do rival label definitions agree on who is positive?",
    "Is the outcome-generating process stationary?",
    "Do near-equal models disagree on decisions?",
    "Is the target attainable from observable features?",
    "Is there an adjudicator with a defined procedure?",
    "Can the decision rule be recovered from the ask?",
    "Do stakeholders' loss functions agree?"
  ),
  evidence = c(
    "Label agreement across rival definitions (kappa or rank)",
    "Out-of-time decay, PSI",
    "Share of decisions that flip among near-best models",
    "Skill ceiling against required skill",
    "Rubric: exists, independent, has a procedure",
    "Recoverability",
    "Consensus"
  ),
  prompt_version = rep("1.0.0", length(liminal_dimension_names))
)

#' The seven dimensions of liminal space
#'
#' Returns the canonical registry of the seven dimensions on which the
#' liminal space between a business ask and a data-based solution is
#' measured. The registry carries the code-level `name` used in score
#' vectors and weights, the plain-language `title` and `formal_name`
#' from the README, the question a business owner and a data scientist
#' can answer for each dimension, the `evidence` one would collect, and
#' the `prompt_version` of the template used to score it with an LLM.
#'
#' @return A tibble with one row per dimension and the columns `name`,
#'   `title`, `formal_name`, `question_business`,
#'   `question_data_scientist`, `evidence` and `prompt_version`.
#' @export
#' @examples
#' liminal2::liminal_dimensions()
liminal_dimensions <- function() {
  liminal_dimension_registry
}

#' Render the seven dimension prompts
#'
#' Renders the seven versioned prompt templates shipped in
#' `inst/prompts/`, one per liminal dimension, with the business ask
#' and the optional situation interpolated as data. The templates embed
#' a fixed anchor rubric and a fixed direction statement, so scores are
#' comparable across business cases (see the package specification).
#'
#' The rendered prompts are plain text; scoring them against a model is
#' the job of [assess_liminal_space()].
#'
#' @param ask A single non-empty character string: the business ask,
#'   verbatim, in whatever language it was written.
#' @param situation `NULL` or a single character string with context,
#'   data state and known constraints. When `NULL`, the prompts state
#'   that no additional situation was supplied.
#' @return A named list of seven character strings, one per dimension,
#'   in canonical dimension order.
#' @export
#' @examples
#' prompts <- liminal2::liminal_prompts(
#'   ask = "Build us a churn model so we can prioritise retention spend."
#' )
#' names(prompts)
#' cat(prompts$shared_meaning)
liminal_prompts <- function(ask, situation = NULL) {
  validate_ask(ask)
  validate_situation(situation)

  situation_rendered <- if (is.null(situation)) {
    "No additional situation was supplied."
  } else {
    situation
  }

  prompts <- purrr::map(liminal_dimension_names, function(name) {
    ellmer::interpolate_package(
      "liminal2",
      paste0(name, ".md"),
      ask = ask,
      situation = situation_rendered
    )
  })

  # interpolate_package() returns glue strings; keep the plain
  # character vector and attach the canonical dimension names.
  prompts <- as.character(prompts)
  stats::setNames(prompts, liminal_dimension_names)
}
