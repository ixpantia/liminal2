#' Default component weights
#'
#' The canonical measurement model uses named weights for the six
#' components. Weights are not silently normalised; they must sum to one.
#'
#' @return A named numeric vector with names `a1` to `a6`.
#' @export
#' @examples
#' default_weights()
default_weights <- function() {
  c(
    a1 = 0.20,
    a2 = 0.15,
    a3 = 0.15,
    a4 = 0.20,
    a5 = 0.15,
    a6 = 0.15
  )
}

.component_names <- function() {
  c("a1", "a2", "a3", "a4", "a5", "a6")
}

.check_prob <- function(x, name = "x", allow_na = FALSE) {
  if (!is.numeric(x) || length(x) != 1L) {
    stop("`", name, "` must be a single numeric value.", call. = FALSE)
  }
  if (allow_na && is.na(x)) {
    return(invisible(x))
  }
  if (!is.finite(x) || x < 0 || x > 1) {
    stop("`", name, "` must be a finite value in [0, 1].", call. = FALSE)
  }
  invisible(x)
}

.check_prob_vector <- function(x, name = "a", allow_na = FALSE) {
  if (!is.numeric(x) || length(x) == 0L) {
    stop("`", name, "` must be a non-empty numeric vector.", call. = FALSE)
  }
  if (!allow_na && any(!is.finite(x))) {
    stop("`", name, "` must contain only finite values.", call. = FALSE)
  }
  if (any(x < 0 | x > 1, na.rm = TRUE)) {
    stop("`", name, "` must contain values in [0, 1].", call. = FALSE)
  }
  invisible(x)
}

.check_weights <- function(w, components = .component_names(), name = "w") {
  if (!is.numeric(w) || length(w) != length(components)) {
    stop(
      "`", name, "` must be a named numeric vector of length ",
      length(components), ".",
      call. = FALSE
    )
  }
  if (is.null(names(w)) || any(!nzchar(names(w)))) {
    stop("`", name, "` must have non-empty names.", call. = FALSE)
  }
  if (anyDuplicated(names(w))) {
    stop("`", name, "` must not contain duplicated names.", call. = FALSE)
  }
  if (!setequal(names(w), components)) {
    stop(
      "`", name, "` must be named exactly: ",
      paste(components, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  w <- w[components]
  if (any(!is.finite(w)) || any(w < 0)) {
    stop("`", name, "` must contain finite non-negative weights.",
      call. = FALSE
    )
  }
  if (!isTRUE(all.equal(sum(w), 1, tolerance = 1e-8))) {
    stop("`", name, "` must sum to 1.", call. = FALSE)
  }
  if (all(w == 0)) {
    stop("`", name, "` must contain at least one positive weight.",
      call. = FALSE
    )
  }
  w
}

.check_scalar_number <- function(x, name = "x", lower = -Inf, upper = Inf,
                                 lower_open = FALSE, upper_open = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    stop("`", name, "` must be a single finite numeric value.",
      call. = FALSE
    )
  }
  lower_bad <- if (lower_open) x <= lower else x < lower
  upper_bad <- if (upper_open) x >= upper else x > upper
  if (lower_bad || upper_bad) {
    stop("`", name, "` is outside the permitted range.", call. = FALSE)
  }
  invisible(x)
}

.check_positive_integer <- function(x, name = "x", minimum = 1L) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) ||
    x != floor(x) || x < minimum) {
    stop(
      "`", name, "` must be a single integer greater than or equal to ",
      minimum, ".",
      call. = FALSE
    )
  }
  as.integer(x)
}

.check_seed <- function(seed) {
  if (is.null(seed)) {
    return(invisible(NULL))
  }
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed) ||
    seed != floor(seed) || seed < 0 || seed > .Machine$integer.max) {
    stop(
      "`seed` must be NULL or a single integer between 0 and ",
      .Machine$integer.max, ".",
      call. = FALSE
    )
  }
  invisible(as.integer(seed))
}

.run_seeded <- function(seed, fn) {
  .check_seed(seed)
  if (is.null(seed)) {
    return(fn())
  }
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  }
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(as.integer(seed))
  fn()
}

.data_digest <- function(x) {
  raw <- serialize(x, connection = NULL, version = 2)
  ints <- as.numeric(raw)
  hash <- sum((ints + 1) * seq_along(ints)) %% 9007199254740991
  paste0(length(raw), "-", format(hash, scientific = FALSE))
}

.package_version <- function() {
  version <- tryCatch(
    as.character(utils::packageVersion("liminal2")),
    error = function(e) "0.1.0"
  )
  version
}

.provenance <- function(args, data = NULL, seed = NULL, call = NULL) {
  list(
    call = call,
    args = args,
    data_digest = if (is.null(data)) NA_character_ else .data_digest(data),
    seed = seed,
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    liminal2_version = .package_version()
  )
}

.check_data <- function(x, name = "X") {
  if (is.null(x) || (!methods::is(x, "data.frame") &&
    !methods::is(x, "matrix"))) {
    stop("`", name, "` must be a data.frame or a matrix.", call. = FALSE)
  }
  if (nrow(x) < 1L || ncol(x) < 1L) {
    stop("`", name, "` must have at least one row and one column.",
      call. = FALSE
    )
  }
  invisible(x)
}

.as_binary <- function(y, name = "y") {
  if (is.factor(y)) {
    if (nlevels(droplevels(y)) != 2L) {
      stop("`", name, "` must have exactly two classes.", call. = FALSE)
    }
    y <- droplevels(y)
    return(as.integer(y) - 1L)
  }
  if (is.character(y) || is.logical(y)) {
    y <- factor(y)
    if (nlevels(y) != 2L) {
      stop("`", name, "` must have exactly two classes.", call. = FALSE)
    }
    return(as.integer(y) - 1L)
  }
  if (!is.numeric(y)) {
    stop("`", name, "` must be numeric, logical, character or a factor.",
      call. = FALSE
    )
  }
  values <- sort(unique(y[!is.na(y)]))
  if (!identical(values, c(0, 1)) && !identical(values, c(0L, 1L))) {
    stop("`", name, "` must be binary and coded as 0/1.", call. = FALSE)
  }
  if (anyNA(y)) {
    stop("`", name, "` must not contain missing values.", call. = FALSE)
  }
  as.integer(y)
}

.check_scores <- function(scores, items, name = "scores") {
  if (!is.numeric(scores) || is.null(names(scores))) {
    stop("`", name, "` must be a named numeric vector.", call. = FALSE)
  }
  if (anyDuplicated(names(scores))) {
    stop("`", name, "` must not contain duplicated item names.",
      call. = FALSE
    )
  }
  if (!setequal(names(scores), items)) {
    stop(
      "`", name, "` must contain exactly these items: ",
      paste(items, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  scores <- scores[items]
  allowed <- c(0, 0.25, 0.5, 0.75, 1)
  ok <- vapply(
    scores,
    function(value) {
      any(abs(value - allowed) <= 1e-8)
    },
    logical(1)
  )
  if (!all(ok)) {
    stop(
      "Every score in `", name, "` must be one of 0, 0.25, 0.5, 0.75, 1.",
      call. = FALSE
    )
  }
  scores
}

.clamp_warn <- function(x, name, lower = 0, upper = 1) {
  if (!is.finite(x)) {
    stop("`", name, "` could not be estimated as a finite value.",
      call. = FALSE
    )
  }
  if (x < lower || x > upper) {
    warning(
      "`", name, "` was outside [", lower, ", ", upper,
      "] and has been clamped.",
      call. = FALSE
    )
    x <- min(max(x, lower), upper)
  }
  x
}

.set_attributes <- function(x, ...) {
  attributes(x) <- c(attributes(x), list(...))
  x
}
