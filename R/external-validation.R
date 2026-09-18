#' Protected external-domain validation without refitting
#'
#' Applies the already fitted preprocessing, feature, model and calibration state to a
#' genuinely external dataset. No model component is updated from external labels.
#' @export
smf_external_validate <- function(result, external_data, domain_name="external", metrics=NULL,
                                  truth=NULL, id_column=NULL) {
  if (!S7::S7_inherits(result, ExperimentResult))
    cli::cli_abort("{.arg result} must be an ExperimentResult.")
  domain_name <- .smf_scalar_chr(domain_name, "domain_name")
  if (!is.data.frame(external_data) || !nrow(external_data))
    cli::cli_abort("{.arg external_data} must be a non-empty data frame.")
  target <- result@spec@task@target
  if (is.null(truth)) {
    if (all(target %in% names(external_data))) truth <- .smf_target_data(external_data, result@spec@task)
  }
  # smf_predict() replays the frozen preprocessing, feature state and probability calibrator.
  pred <- smf_predict(result, external_data)
  metric_tbl <- data.frame()
  if (!is.null(truth)) {
    metric_specs <- metrics %||% result@spec@metrics
    metric_tbl <- smf_evaluate(truth, pred, metric_specs,
      positive_label=if(length(result@spec@task@positive_label)) as.character(result@spec@task@positive_label) else NULL,
      threshold=if(is.null(result@spec@imbalance)) 0.5 else result@spec@imbalance@threshold)
  }
  diag <- .smf_external_domain_diagnostics(result, external_data)
  warnings <- list()
  if (isTRUE(diag$unseen_levels > 0L)) warnings[[length(warnings)+1L]] <- smf_warning_record(
    "EXTERNAL_UNSEEN_LEVELS", "External data contain categorical levels absent from model-development preprocessing.",
    severity="high", evidence=diag, suggested_action="Inspect domain shift and avoid unsupported interpretation.", override_allowed=FALSE)
  if (isTRUE(diag$numeric_extreme_fraction > 0.10)) warnings[[length(warnings)+1L]] <- smf_warning_record(
    "EXTERNAL_NUMERIC_SHIFT", "More than 10% of external numeric cells are beyond four training-scale standard deviations.",
    severity="warning", evidence=diag, suggested_action="Report predictor-support shift with external performance.")
  ids <- if (!is.null(id_column) && id_column %in% names(external_data)) external_data[[id_column]] else seq_len(nrow(external_data))
  pred_obj <- list(row_ids=ids, estimate=pred)
  ExternalValidationResult(domain_name=domain_name, metrics=metric_tbl, predictions=pred_obj,
    truth=truth, diagnostics=diag, warnings=warnings,
    provenance=list(source_run_id=result@manifest@run_id, source_spec_hash=result@manifest@spec_hash,
      source_preprocessing_hash=result@manifest@preprocessing_hash, refit=FALSE, recalibration=FALSE,
      external_data_hash=smf_data_hash(external_data), evaluated_at=.smf_now()))
}

.smf_external_domain_diagnostics <- function(result, data) {
  st <- result@fit@preprocessing@state
  unseen <- 0L; unseen_by_feature <- list()
  for (nm in st$categorical) if (nm %in% names(data)) {
    vals <- unique(as.character(data[[nm]][!is.na(data[[nm]])]))
    bad <- setdiff(vals, st$levels[[nm]])
    unseen_by_feature[[nm]] <- bad; unseen <- unseen + length(bad)
  }
  n_extreme <- 0L; n_numeric <- 0L
  for (nm in st$numeric) if (nm %in% names(data)) {
    z <- as.numeric(data[[nm]]); center <- st$centers[[nm]]; scale <- st$scales[[nm]]
    # When centering/scaling were disabled, use an empirical guard only if meaningful state exists.
    if (is.finite(scale) && scale > 0 && (abs(center) > 0 || abs(scale-1) > .Machine$double.eps^0.5)) {
      n_extreme <- n_extreme + sum(abs((z-center)/scale) > 4, na.rm=TRUE)
      n_numeric <- n_numeric + sum(is.finite(z))
    }
  }
  list(n=nrow(data), unseen_levels=unseen, unseen_by_feature=unseen_by_feature,
    numeric_extreme_fraction=if(n_numeric) n_extreme/n_numeric else 0,
    external_hash=smf_data_hash(data))
}

#' Compare internal and external validation domains
#' @export
smf_compare_validation_domains <- function(internal_result, external_result) {
  if (!S7::S7_inherits(internal_result, ExperimentResult)) cli::cli_abort("{.arg internal_result} must be an ExperimentResult.")
  if (!S7::S7_inherits(external_result, ExternalValidationResult)) cli::cli_abort("{.arg external_result} must be an ExternalValidationResult.")
  a <- internal_result@metrics; b <- external_result@metrics
  if (!is.data.frame(a) || !is.data.frame(b) || !nrow(a) || !nrow(b)) return(list(internal=a, external=b, comparison=data.frame()))
  common <- intersect(as.character(a$metric), as.character(b$metric))
  rows <- lapply(common, function(m) {
    ai <- a[a$metric==m,,drop=FALSE][1,]; bi <- b[b$metric==m,,drop=FALSE][1,]
    data.frame(metric=m, internal=ai$value, external=bi$value, delta=bi$value-ai$value,
      direction=ai$direction %||% NA_character_, row.names=NULL)
  })
  list(internal=a, external=b, comparison=if(length(rows)) do.call(rbind,rows) else data.frame(),
    external_diagnostics=external_result@diagnostics, warnings=external_result@warnings)
}
