#' Validate data against a DataSpec
#' @export
smf_validate_schema <- function(data, spec) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data.frame-like object.")
  cols <- unique(c(spec@target, spec@predictors, spec@id_column, spec@categorical, spec@numeric))
  .smf_abort_missing_columns(data, cols, "DataSpec")
  invisible(TRUE)
}

#' Summarize missingness
#' @export
smf_missingness_report <- function(data) {
  data.frame(variable=names(data), n_missing=vapply(data, function(x) sum(is.na(x)), integer(1)), fraction_missing=vapply(data, function(x) mean(is.na(x)), numeric(1)), row.names=NULL)
}

#' Screen predictors for target leakage
#' @export
smf_detect_leakage <- function(data, spec, design=NULL) {
  smf_validate_schema(data, spec)
  target <- spec@target[[1]]
  y <- data[[target]]
  predictors <- if (length(spec@predictors)) spec@predictors else setdiff(names(data), c(spec@target, spec@id_column))
  findings <- list()
  for (nm in predictors) {
    x <- data[[nm]]
    same <- length(x)==length(y) && all((is.na(x) & is.na(y)) | (!is.na(x) & !is.na(y) & as.character(x)==as.character(y)))
    if (same) findings[[length(findings)+1L]] <- smf_warning_record("LEAKAGE_EXACT_TARGET_COPY", paste0("Predictor '",nm,"' is an exact copy of target '",target,"'."), "blocking", evidence=list(feature=nm,target=target), suggested_action="Remove post-outcome/target-derived variables or correct the schema.", override_allowed=FALSE)
    if (is.numeric(x) && is.numeric(y) && length(unique(stats::na.omit(x)))>2L) {
      r <- suppressWarnings(stats::cor(x,y,use="complete.obs"))
      if (is.finite(r) && abs(r)>0.999 && !same) findings[[length(findings)+1L]] <- smf_warning_record("LEAKAGE_NEAR_EXACT_NUMERIC", paste0("Predictor '",nm,"' is almost perfectly correlated with the target."), "high", evidence=list(feature=nm, correlation=r), suggested_action="Verify provenance and whether the predictor is measured before the outcome.")
    }
  }
  findings
}

#' Audit data quality and leakage risk
#' @export
smf_audit_data <- function(data, spec, design=NULL) {
  smf_validate_schema(data, spec)
  missing <- smf_missingness_report(data)
  dup_rows <- which(duplicated(data))
  dup_ids <- integer()
  if (length(spec@id_column)) dup_ids <- which(duplicated(data[[spec@id_column]]))
  card <- data.frame(variable=names(data), n_unique=vapply(data, function(x) length(unique(x[!is.na(x)])), integer(1)), row.names=NULL)
  leakage <- smf_detect_leakage(data, spec, design)
  flags <- list()
  if (length(dup_rows)) flags[[length(flags)+1L]] <- smf_warning_record("DUPLICATE_ROWS", "Duplicate rows were detected.", "warning", evidence=list(rows=dup_rows), suggested_action="Verify whether duplicates represent repeated measurements or accidental duplication.")
  if (length(dup_ids)) flags[[length(flags)+1L]] <- smf_warning_record("DUPLICATE_IDS", "Duplicate IDs were detected.", "high", evidence=list(rows=dup_ids), suggested_action="Confirm the observational unit or declare repeated measurements explicitly.")
  flags <- c(flags, leakage)
  meta <- ResultMeta(run_id=.smf_new_run_id(), created_at=.smf_now(), package_version=.smf_version(), backend="core", backend_version=character(), data_hash=smf_data_hash(data), split_hash=character(), spec_hash=smf_hash(spec), seed=integer(), warnings=flags, provenance=list(operation="data_audit"))
  DataAuditResult(meta=meta, schema=list(names=names(data), classes=vapply(data, function(x) paste(class(x), collapse="/"), character(1)), n=nrow(data), p=ncol(data)), missingness=missing, duplicates=list(rows=dup_rows, ids=dup_ids), cardinality=card, leakage=leakage, quality_flags=flags)
}
