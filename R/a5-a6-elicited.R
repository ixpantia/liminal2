#' @keywords internal
.builtin_rubric <- function(name) {
  if (name == "oracle") {
    items <- c(
      external_authority = 1,
      codified_definition = 1,
      timeliness = 1,
      model_independence = 1,
      inter_judge_agreement = 1,
      ex_post_detectability = 1
    )
    title <- "Oracle strength"
  } else if (name == "normative") {
    items <- c(
      threshold_owner = 1,
      cost_ratio_agreed = 1,
      stakeholder_agreement = 1,
      regulatory_constraint = 1,
      reversibility = 1,
      precedent = 1
    )
    title <- "Normative consensus"
  } else {
    stop("Unknown built-in rubric: `", name, "`.", call. = FALSE)
  }
  weights <- rep(1 / length(items), length(items))
  names(weights) <- names(items)
  list(
    name = name,
    title = title,
    items = items,
    weights = weights
  )
}

#' @keywords internal
.parse_flat_yaml <- function(lines) {
  lines <- sub("#.*$", "", lines)
  lines <- lines[nzchar(trimws(lines))]
  if (length(lines) == 0L) {
    stop("The rubric file is empty.", call. = FALSE)
  }
  result <- list()
  current_section <- NULL
  current_item <- NULL
  for (line in lines) {
    indentation <- nchar(line) - nchar(sub("^ *", "", line))
    text <- trimws(line)
    if (indentation == 0L) {
      if (!grepl("^[A-Za-z_][A-Za-z0-9_]*:", text)) {
        stop("Malformed YAML line: ", text, call. = FALSE)
      }
      key <- sub(":.*$", "", text)
      value <- trimws(sub("^[^:]+:", "", text))
      if (nzchar(value)) {
        result[[key]] <- .yaml_scalar(value)
        current_section <- NULL
        current_item <- NULL
      } else {
        result[[key]] <- list()
        current_section <- key
        current_item <- NULL
      }
    } else if (indentation == 2L && !is.null(current_section)) {
      if (!grepl("^[A-Za-z_][A-Za-z0-9_]*:", text)) {
        stop("Malformed YAML line: ", text, call. = FALSE)
      }
      key <- sub(":.*$", "", text)
      value <- trimws(sub("^[^:]+:", "", text))
      if (nzchar(value)) {
        result[[current_section]][[key]] <- .yaml_scalar(value)
        current_item <- NULL
      } else {
        result[[current_section]][[key]] <- list()
        current_item <- key
      }
    } else if (indentation == 4L && !is.null(current_section) &&
      !is.null(current_item)) {
      if (!grepl("^[^:]+:", text)) {
        stop("Malformed YAML line: ", text, call. = FALSE)
      }
      key <- trimws(sub(":.*$", "", text))
      value <- trimws(sub("^[^:]+:", "", text))
      result[[current_section]][[current_item]][[key]] <-
        .yaml_scalar(value)
    } else {
      stop("Unexpected YAML indentation.", call. = FALSE)
    }
  }
  result
}

#' @keywords internal
.yaml_scalar <- function(value) {
  value <- trimws(value)
  if (nzchar(value) && substr(value, 1, 1) %in% c("\"", "'")) {
    quote <- substr(value, 1, 1)
    if (nchar(value) < 2L || substr(value, nchar(value), nchar(value)) !=
      quote) {
      stop("Unterminated quoted YAML value.", call. = FALSE)
    }
    return(substr(value, 2, nchar(value) - 1L))
  }
  number <- suppressWarnings(as.numeric(value))
  if (!is.na(number)) {
    return(number)
  }
  if (value %in% c("true", "TRUE", "yes")) {
    return(TRUE)
  }
  if (value %in% c("false", "FALSE", "no")) {
    return(FALSE)
  }
  value
}

#' @keywords internal
.validate_rubric <- function(rubric) {
  if (!is.list(rubric) || is.null(rubric$items)) {
    stop("A rubric must contain an `items` field.", call. = FALSE)
  }
  items <- rubric$items
  if (is.list(items)) {
    item_names <- names(items)
  } else if (is.character(items)) {
    item_names <- unname(items)
  } else {
    stop("Rubric `items` must be a mapping or a character vector.",
      call. = FALSE
    )
  }
  if (length(item_names) == 0L || any(!nzchar(item_names))) {
    stop("Rubric items must have non-empty names.", call. = FALSE)
  }
  if (anyDuplicated(item_names)) {
    stop("Rubric item names must be unique.", call. = FALSE)
  }
  rubric$item_names <- item_names
  if (is.null(rubric$weights)) {
    rubric$weights <- rep(1 / length(item_names), length(item_names))
    names(rubric$weights) <- item_names
  } else {
    weights <- unlist(rubric$weights, use.names = TRUE)
    if (is.null(names(weights)) || !setequal(names(weights), item_names)) {
      stop("Rubric weights must be named after the rubric items.",
        call. = FALSE
      )
    }
    weights <- weights[item_names]
    if (any(!is.finite(weights)) || any(weights < 0) ||
      sum(weights) <= 0) {
      stop("Rubric weights must be finite and non-negative.",
        call. = FALSE
      )
    }
    rubric$weights <- weights / sum(weights)
  }
  rubric
}

#' Read a rubric file
#'
#' Reads a rubric from a YAML file. The `yaml` package is used when
#' available; a restricted parser handles the bundled files otherwise.
#'
#' @param path A file path, or one of `"oracle"` or `"normative"` to read a
#'   bundled rubric.
#'
#' @return A validated rubric list.
#' @export
#' @examples
#' read_rubric("oracle")$name
read_rubric <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    stop("`path` must be a non-empty string.", call. = FALSE)
  }
  if (path %in% c("oracle", "normative")) {
    bundled <- system.file(
      "rubrics",
      paste0(path, ".yml"),
      package = "liminal2"
    )
    if (!nzchar(bundled)) {
      return(.validate_rubric(.builtin_rubric(path)))
    }
    path <- bundled
  }
  if (!file.exists(path)) {
    stop("Rubric file does not exist: ", path, call. = FALSE)
  }
  rubric <- if (requireNamespace("yaml", quietly = TRUE)) {
    tryCatch(
      yaml::yaml.load_file(path, eval.expr = FALSE),
      error = function(e) {
        stop("Malformed YAML in rubric file: ", conditionMessage(e),
          call. = FALSE
        )
      }
    )
  } else {
    .parse_flat_yaml(readLines(path, warn = FALSE))
  }
  .validate_rubric(rubric)
}

#' Score an elicited rubric
#'
#' Computes a weighted mean of anchored rubric scores. Scores must use the
#' six ordinal anchors 0, 0.25, 0.5, 0.75 and 1.
#'
#' @param scores A named numeric vector with one score per rubric item.
#' @param rubric A rubric name (`"oracle"` or `"normative"`) or a path to a
#'   rubric YAML file.
#' @param weights Optional named weights over the rubric items. They are
#'   rescaled to sum to one.
#'
#' @return A finite scalar in the unit interval with item scores attached.
#' @export
#' @examples
#' scores <- c(
#'   external_authority = 1,
#'   codified_definition = 1,
#'   timeliness = 0.75,
#'   model_independence = 1,
#'   inter_judge_agreement = 0.75,
#'   ex_post_detectability = 1
#' )
#' rubric_score(scores, "oracle")
rubric_score <- function(scores, rubric = "oracle", weights = NULL) {
  rubric <- read_rubric(rubric)
  items <- rubric$item_names
  scores <- .check_scores(scores, items)
  if (is.null(weights)) {
    weights <- rubric$weights
  } else {
    if (!is.numeric(weights) || is.null(names(weights))) {
      stop("`weights` must be a named numeric vector.", call. = FALSE)
    }
    if (!setequal(names(weights), items)) {
      stop("`weights` must be named after the rubric items.",
        call. = FALSE
      )
    }
    weights <- weights[items]
    if (any(!is.finite(weights)) || any(weights < 0) ||
      sum(weights) <= 0) {
      stop("`weights` must be finite and non-negative.", call. = FALSE)
    }
    weights <- weights / sum(weights)
  }
  value <- sum(scores * weights)
  value <- .clamp_warn(value, "rubric score")
  attr(value, "items") <- scores
  attr(value, "weights") <- weights
  attr(value, "rubric") <- rubric$name
  value
}

#' @keywords internal
.rubric_items <- function(rubric) {
  read_rubric(rubric)$item_names
}

#' @keywords internal
.rubric_mean <- function(scores, rubric = "oracle", resample = FALSE) {
  rubric <- read_rubric(rubric)
  items <- rubric$item_names
  weights <- rubric$weights
  anchors <- c(0, 0.25, 0.5, 0.75, 1)
  if (is.list(scores) && !is.data.frame(scores)) {
    scores <- do.call(rbind, scores)
  }
  if (is.data.frame(scores)) {
    scores <- as.matrix(scores)
  }
  if (is.matrix(scores)) {
    if (is.null(colnames(scores)) || !setequal(colnames(scores), items)) {
      stop("Expert score matrices must be named after the rubric items.",
        call. = FALSE
      )
    }
    scores <- scores[, items, drop = FALSE]
    storage.mode(scores) <- "double"
    valid <- apply(scores, 1L, function(row) {
      all(vapply(
        row,
        function(value) any(abs(value - anchors) <= 1e-8),
        logical(1)
      ))
    })
    if (!all(valid)) {
      stop("Every expert score must use the ordinal anchors.",
        call. = FALSE
      )
    }
    if (resample) {
      index <- sample.int(nrow(scores), nrow(scores), replace = TRUE)
      sampled <- scores[index, , drop = FALSE]
      return(sum(colMeans(sampled) * weights))
    }
    expert_scores <- drop(scores %*% weights)
    value <- mean(expert_scores)
    attr(value, "expert_scores") <- expert_scores
    attr(value, "expert_sd") <- if (length(expert_scores) > 1L) {
      stats::sd(expert_scores)
    } else {
      0
    }
    return(value)
  }
  scores <- .check_scores(scores, items)
  if (resample) {
    sampled <- vapply(scores, function(value) {
      spread <- exp(-((anchors - value)^2) / (2 * 0.125^2))
      sample(anchors, size = 1L, prob = spread / sum(spread))
    }, numeric(1))
    names(sampled) <- items
    return(sum(sampled * weights))
  }
  value <- sum(scores * weights)
  attr(value, "items") <- scores
  attr(value, "weights") <- weights
  attr(value, "rubric") <- rubric$name
  value
}
