#' Fit the 0.1.0 preprocessing state on training data only
#' @export
smf_fit_preprocessor <- function(data, spec, data_spec, role=c("training","test","validation")) {
  role <- match.arg(role)
  if (role != "training") .smf_abort("PREPROCESS_FIT_NONTRAINING", "Managed preprocessing can only be fitted on training data.", evidence=list(role=role), class="smf_leakage_error")
  smf_validate_schema(data, data_spec)
  predictors <- if (length(data_spec@predictors)) data_spec@predictors else setdiff(names(data), c(data_spec@target, data_spec@id_column))
  x <- data[predictors]
  numeric_cols <- names(x)[vapply(x, is.numeric, logical(1))]
  categorical_cols <- setdiff(names(x), numeric_cols)
  centers <- scales <- imputes <- list()
  for (nm in numeric_cols) {
    z <- x[[nm]]
    if (spec@impute_numeric == "mean") imputes[[nm]] <- mean(z, na.rm=TRUE)
    else if (spec@impute_numeric == "median") imputes[[nm]] <- stats::median(z, na.rm=TRUE)
    else imputes[[nm]] <- NA_real_
    z2 <- z
    if (!is.na(imputes[[nm]])) z2[is.na(z2)] <- imputes[[nm]]
    centers[[nm]] <- if (spec@center) mean(z2, na.rm=TRUE) else 0
    s <- if (spec@scale) stats::sd(z2, na.rm=TRUE) else 1
    scales[[nm]] <- if (is.finite(s) && s>0) s else 1
  }
  levels <- lapply(x[categorical_cols], function(z) sort(unique(as.character(z[!is.na(z)]))))
  state <- list(predictors=predictors, numeric=numeric_cols, categorical=categorical_cols, imputes=imputes, centers=centers, scales=scales, levels=levels)
  Preprocessor(spec=spec, data_spec=data_spec, training_hash=smf_data_hash(data), state=state, fitted=TRUE)
}

#' Apply a fitted preprocessor without refitting it
#' @export
smf_apply_preprocessor <- function(preprocessor, data) {
  if (!isTRUE(preprocessor@fitted)) cli::cli_abort("Preprocessor is not fitted.")
  st <- preprocessor@state; spec <- preprocessor@spec
  .smf_abort_missing_columns(data, st$predictors, "preprocessor")
  out <- data.frame(row.names=seq_len(nrow(data)))
  for (nm in st$numeric) {
    z <- as.numeric(data[[nm]])
    imp <- st$imputes[[nm]]
    if (!is.na(imp)) z[is.na(z)] <- imp
    z <- (z - st$centers[[nm]]) / st$scales[[nm]]
    out[[nm]] <- z
  }
  for (nm in st$categorical) {
    z <- as.character(data[[nm]])
    lv <- st$levels[[nm]]
    if (spec@one_hot) {
      for (lev in lv) out[[paste0(nm,"__",make.names(lev))]] <- as.integer(!is.na(z) & z==lev)
    } else {
      out[[nm]] <- factor(z, levels=lv)
    }
  }
  out
}

#' Return preprocessing provenance
#' @export
smf_preprocess_provenance <- function(preprocessor) list(training_hash=preprocessor@training_hash, state_hash=smf_hash(preprocessor@state), fitted=preprocessor@fitted)
