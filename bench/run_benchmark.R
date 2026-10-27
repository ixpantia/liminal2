#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

get_argument <- function(name, default = NULL) {
  position <- match(name, args)
  if (is.na(position)) {
    return(default)
  }
  if (position == length(args)) {
    stop("Missing value for ", name, call. = FALSE)
  }
  args[position + 1L]
}

seed <- as.integer(get_argument("--seed", "42"))
out <- get_argument("--out", "bench/results.csv")
quick <- "--quick" %in% args

suppressPackageStartupMessages(library(liminal2))

registry <- scenario_registry()
rows <- vector("list", nrow(registry))
assessments <- vector("list", nrow(registry))

for (index in seq_len(nrow(registry))) {
  id <- registry$id[index]
  scenario <- generate_scenario(id, seed = seed)
  component_args <- scenario$truth$component_args
  if (quick) {
    component_args$a3$B <- min(component_args$a3$B, 20L)
    component_args$a4$repeats <- 2L
  }
  assessment <- assess_goal(
    label_defs = scenario$label_defs,
    X = scenario$X,
    time_index = scenario$time_index,
    y = scenario$y,
    oracle_scores = scenario$rubric$oracle,
    normative_scores = scenario$rubric$normative,
    component_args = component_args,
    seed = seed
  )
  assessments[[index]] <- assessment
  error <- abs(assessment$L - scenario$truth$target_L)
  tolerance <- if (id %in% c("S1", "S2", "S3")) 0.06 else 0.08
  rows[[index]] <- data.frame(
    id = id,
    target_A = scenario$truth$target_A,
    target_L = scenario$truth$target_L,
    A = assessment$A,
    L = assessment$L,
    a1 = assessment$components[["a1"]],
    a2 = assessment$components[["a2"]],
    a3 = assessment$components[["a3"]],
    a4 = assessment$components[["a4"]],
    a5 = assessment$components[["a5"]],
    a6 = assessment$components[["a6"]],
    abs_error = error,
    tolerance = tolerance,
    recovery_pass = error <= tolerance,
    stringsAsFactors = FALSE
  )
  cat(
    id, " L =", round(assessment$L, 4),
    " target =", scenario$truth$target_L,
    " error =", round(error, 4), "\n"
  )
}

results <- do.call(rbind, rows)
result_L <- results$L
target_L <- results$target_L
ordering <- all(diff(result_L) > 0)
spearman <- stats::cor(result_L, target_L, method = "spearman")

S3 <- generate_scenario("S3", seed = seed)
S3_leak <- generate_scenario("S3_leak", seed = seed)
S3_audit <- audit_leakage(
  S3$X, S3$y,
  permutations = if (quick) 10L else 20L,
  repeats = 2,
  seed = seed
)
S3_leak_audit <- audit_leakage(
  S3_leak$X, S3_leak$y,
  permutations = if (quick) 10L else 20L,
  repeats = 2,
  seed = seed
)

S1_null <- generate_scenario("S1_null", seed = seed)
null_a4 <- discriminability(
  S1_null$X, S1_null$y,
  folds = 5, repeats = 3, seed = seed
)

component_vectors <- lapply(assessments, `[[`, "components")
pair_ranking <- numeric(0)
for (first in seq_len(length(component_vectors) - 1L)) {
  for (second in (first + 1L):length(component_vectors)) {
    sensitivity <- weight_sensitivity(
      list(component_vectors[[first]], component_vectors[[second]]),
      n = if (quick) 200L else 1000L,
      seed = seed
    )
    expected <- result_L[first] < result_L[second]
    preserved <- if (expected) {
      sensitivity$ranking_fraction
    } else {
      1 - sensitivity$ranking_fraction
    }
    pair_ranking <- c(pair_ranking, preserved)
  }
}

criteria <- data.frame(
  criterion = c(
    "strict_ordering",
    "spearman_one",
    "recovery",
    "S3_leak_a4",
    "S3_leak_flagged",
    "S3_not_flagged",
    "S1_null_a4",
    "weight_ranking"
  ),
  pass = c(
    ordering,
    isTRUE(all.equal(spearman, 1, tolerance = 1e-8)),
    all(results$recovery_pass),
    unname(S3_leak_audit$a4) > 0.9,
    isTRUE(S3_leak_audit$flagged),
    !isTRUE(S3_audit$flagged),
    unname(null_a4) <= 0.05,
    length(pair_ranking) > 0L && min(pair_ranking) >= 0.95
  ),
  value = c(
    ordering,
    spearman,
    sum(results$recovery_pass),
    unname(S3_leak_audit$a4),
    S3_leak_audit$flagged,
    S3_audit$flagged,
    unname(null_a4),
    if (length(pair_ranking) == 0L) NA_real_ else min(pair_ranking)
  ),
  stringsAsFactors = FALSE
)

output_directory <- dirname(out)
if (!dir.exists(output_directory)) {
  dir.create(output_directory, recursive = TRUE)
}
utils::write.csv(results, out, row.names = FALSE)
utils::write.csv(
  criteria,
  file.path(output_directory, "criteria.csv"),
  row.names = FALSE
)
cat("\nAcceptance criteria:\n")
print(criteria, row.names = FALSE)
cat("\nWrote", out, "\n")
if (!all(criteria$pass)) {
  stop("One or more benchmark acceptance criteria failed.", call. = FALSE)
}
