.smf_scalar_chr <- function(x, name, allow_empty = FALSE) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || (!allow_empty && !nzchar(x))) {
    cli::cli_abort("{.arg {name}} must be a single non-missing character value.")
  }
  x
}

.smf_scalar_lgl <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {name}} must be TRUE or FALSE.")
  }
  x
}

.smf_scalar_num <- function(x, name, lower = -Inf, upper = Inf, open_lower = FALSE, open_upper = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x)) {
    cli::cli_abort("{.arg {name}} must be one finite numeric value.")
  }
  bad_lower <- if (open_lower) x <= lower else x < lower
  bad_upper <- if (open_upper) x >= upper else x > upper
  if (bad_lower || bad_upper) {
    cli::cli_abort("{.arg {name}} is outside the allowed range.")
  }
  x
}

.smf_chr <- function(x) {
  if (is.null(x)) character() else as.character(x)
}

.smf_named_list <- function(x, name = "x") {
  if (!is.list(x)) cli::cli_abort("{.arg {name}} must be a list.")
  x
}

.smf_compact <- function(x) x[!vapply(x, is.null, logical(1))]

.smf_version <- function() {
  tryCatch(as.character(utils::packageVersion("sciModelFlowR")), error = function(e) "0.9.0")
}

.smf_now <- function() format(Sys.time(), tz = "UTC", usetz = TRUE)

.smf_new_run_id <- function() {
  stamp <- format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC")
  token <- paste(stamp, Sys.getpid(), format(proc.time()[[3]], digits = 16), sep = "|")
  paste0("smf-", stamp, "-", substr(digest::digest(token, algo = "sha256", serialize = FALSE), 1, 8))
}

.smf_existing_columns <- function(data, columns) {
  columns <- unique(columns[nzchar(columns)])
  setdiff(columns, names(data))
}

.smf_abort_missing_columns <- function(data, columns, context = "data") {
  missing <- .smf_existing_columns(data, columns)
  if (length(missing)) {
    cli::cli_abort(c(
      "Columns required by {context} are missing.",
      "x" = paste(missing, collapse = ", ")
    ))
  }
  invisible(TRUE)
}

.smf_is_s7 <- function(x) S7::S7_inherits(x)

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

.smf_package_available <- function(package) {
  package <- .smf_chr(package)
  if (!length(package)) return(TRUE)
  all(vapply(package, function(p) nzchar(system.file(package = p)), logical(1)))
}

.smf_clip_prob <- function(p, eps = 1e-15) pmin(pmax(as.numeric(p), eps), 1 - eps)

.smf_softmax <- function(z) {
  z <- as.matrix(z)
  z <- z - apply(z, 1L, max)
  ez <- exp(z)
  ez / rowSums(ez)
}
