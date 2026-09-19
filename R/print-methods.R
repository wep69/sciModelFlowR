S7::method(print, ExperimentResult) <- function(x, ...) {
  cat("<sciModelFlowR ExperimentResult>\n")
  cat("  task:   ", x@spec@task@kind, "\n", sep = "")
  cat("  target: ", paste(x@spec@task@target, collapse = ", "), "\n", sep = "")
  cat("  engine: ", x@spec@model@engine, "\n", sep = "")
  cat("  split:  ", x@split@method, " (", length(x@split@train_index),
      " train / ", length(x@split@test_index), " test)\n", sep = "")
  print(x@metrics, row.names = FALSE)
  invisible(x)
}

S7::method(summary, ExperimentResult) <- function(object, ...) {
  list(
    task = object@spec@task@kind,
    target = object@spec@task@target,
    model = smf_to_list(object@spec@model),
    metrics = object@metrics,
    warnings = lapply(object@meta@warnings, smf_to_list),
    manifest = smf_to_list(object@manifest)
  )
}

S7::method(print, DataAuditResult) <- function(x, ...) {
  cat("<sciModelFlowR DataAuditResult>\n")
  cat("  rows: ", x@schema$n, "\n", sep = "")
  cat("  columns: ", x@schema$p, "\n", sep = "")
  cat("  quality flags: ", length(x@quality_flags), "\n", sep = "")
  invisible(x)
}

S7::method(print, ResampleResult) <- function(x, ...) {
  cat("<sciModelFlowR ResampleResult>\n")
  cat("  method: ", x@resamples@method, "\n", sep="")
  cat("  splits: ", length(x@resamples@splits), "\n", sep="")
  print(x@aggregate,row.names=FALSE)
  invisible(x)
}

S7::method(print, BootstrapResult) <- function(x, ...) {
  cat("<sciModelFlowR BootstrapResult>\n")
  cat("  method: ", x@spec@method, "\n", sep="")
  cat("  successful/failed: ", x@successful, "/", x@failed, "\n", sep="")
  print(x@interval)
  invisible(x)
}

S7::method(print, FeatureSelectionResult) <- function(x, ...) {
  cat("<sciModelFlowR FeatureSelectionResult>\n")
  cat("  method: ", x@spec@method, "\n", sep="")
  cat("  selected: ", length(x@selected), "\n", sep="")
  if(length(x@selected)) cat("  ", paste(x@selected,collapse=", "), "\n", sep="")
  invisible(x)
}


S7::method(print, PredictionDistribution) <- function(x, ...) {
  cat("<sciModelFlowR PredictionDistribution>\n")
  cat("  representation: ", x@representation, "\n", sep = "")
  ops <- if (is.list(x@capabilities)) names(Filter(isTRUE, x@capabilities)) else as.character(x@capabilities)
  if (length(ops)) cat("  capabilities: ", paste(ops, collapse = ", "), "\n", sep = "")
  invisible(x)
}

S7::method(print, CalibrationResult) <- function(x, ...) {
  cat("<sciModelFlowR CalibrationResult>\n")
  cat("  method: ", x@method, "\n", sep = "")
  cat("  source: ", x@source, "\n", sep = "")
  cat("  calibration rows: ", x@n, "\n", sep = "")
  if (length(x@class_levels)) cat("  classes: ", paste(x@class_levels, collapse = ", "), "\n", sep = "")
  invisible(x)
}

S7::method(print, ImbalanceResult) <- function(x, ...) {
  cat("<sciModelFlowR ImbalanceResult>\n")
  cat("  method: ", x@method, "\n", sep = "")
  cat("  before: ", paste(names(x@before), unlist(x@before), sep = "=", collapse = ", "), "\n", sep = "")
  cat("  after: ", paste(names(x@after), unlist(x@after), sep = "=", collapse = ", "), "\n", sep = "")
  invisible(x)
}

S7::method(print, TuningResult) <- function(x, ...) {
  cat("<sciModelFlowR TuningResult>\n")
  cat("  method: ", x@spec@method, "\n", sep="")
  cat("  trials: ", if(is.data.frame(x@archive)) nrow(x@archive) else 0L, "\n", sep="")
  cat("  objectives: ", paste(vapply(x@spec@objectives, function(m) m@name, character(1)), collapse=", "), "\n", sep="")
  sel_txt <- if(!is.null(x@selected)) {
    x@selected$config_id[[1]]
  } else if(.smf_tuning_archive_all_na(x@archive, x@spec@objectives)) {
    "none (no trial produced finite objective values)"
  } else {
    "none (explicit compromise required for multi-objective tuning)"
  }
  cat("  selected: ", sel_txt, "\n", sep="")
  invisible(x)
}

S7::method(print, NestedTuningResult) <- function(x, ...) {
  cat("<sciModelFlowR NestedTuningResult>\n")
  cat("  outer folds: ", length(x@outer_results), "\n", sep="")
  cat("  selection estimate: inner resampling\n")
  cat("  generalization estimate: outer resampling\n")
  invisible(x)
}

S7::method(print, BenchmarkResult) <- function(x, ...) {
  cat("<sciModelFlowR BenchmarkResult>\n")
  cat("  candidates: ", length(x@benchmark_spec@candidates), "\n", sep="")
  cat("  shared resampling hash: ", x@resamples@manifest_hash, "\n", sep="")
  if (is.null(x@decision)) cat("  decision: none; no universal winner is emitted\n") else cat("  decision: explicit rule applied\n")
  invisible(x)
}


S7::method(print, ExplainResult) <- function(x, ...) {
  cat("<sciModelFlowR ExplainResult>\n")
  cat("  methods: ", x@method, "\n", sep="")
  cat("  scope: ", x@scope, "\n", sep="")
  cat("  causal interpretation: FALSE\n")
  cat("  warnings: ", length(x@warnings), "\n", sep="")
  invisible(x)
}

S7::method(print, ExplanationStabilityResult) <- function(x, ...) {
  cat("<sciModelFlowR ExplanationStabilityResult>\n")
  cat("  method: ", x@method, "\n", sep="")
  cat("  folds: ", length(x@resamples@splits), "\n", sep="")
  if (is.data.frame(x@topk_stability) && nrow(x@topk_stability)) cat("  mean top-k Jaccard: ", round(x@topk_stability$mean_topk_jaccard[[1]],3), "\n", sep="")
  cat("  causal interpretation: FALSE\n")
  invisible(x)
}


S7::method(print, DLArchitecture) <- function(x, ...) {
  cat("<sciModelFlowR DLArchitecture>\n")
  cat("  kind: ", x@kind, "\n", sep="")
  cat("  modality: ", x@modality, "\n", sep="")
  cat("  output_dim: ", x@output_dim, "\n", sep="")
  invisible(x)
}

S7::method(print, DLFitResult) <- function(x, ...) {
  cat("<sciModelFlowR DLFitResult>\n")
  cat("  backend: ", x@backend, "\n", sep="")
  cat("  architecture: ", x@architecture@kind, "\n", sep="")
  cat("  device/precision: ", x@device, "/", x@precision, "\n", sep="")
  invisible(x)
}

S7::method(print, DLUncertaintyResult) <- function(x, ...) {
  cat("<sciModelFlowR DLUncertaintyResult>\n")
  cat("  decomposition identified: ", isTRUE(x@provenance$identified), "\n", sep="")
  invisible(x)
}

S7::method(print, DLGradientExplanation) <- function(x, ...) {
  cat("<sciModelFlowR DLGradientExplanation>\n")
  cat("  method: ", x@method, "\n", sep="")
  cat("  causal interpretation: FALSE\n")
  invisible(x)
}


S7::method(print, ExternalValidationResult) <- function(x, ...) {
  cat("<sciModelFlowR ExternalValidationResult>\n")
  cat("  domain: ", x@domain_name, "\n", sep="")
  cat("  refit/recalibration: FALSE/FALSE\n")
  if(is.data.frame(x@metrics) && nrow(x@metrics)) print(x@metrics,row.names=FALSE)
  invisible(x)
}

S7::method(print, ReportingResult) <- function(x, ...) {
  cat("<sciModelFlowR ReportingResult>\n")
  cat("  format: ", x@format, "\n", sep="")
  if(length(x@path)) cat("  path: ", x@path, "\n", sep="")
  invisible(x)
}

S7::method(print, ReleaseCandidateAudit) <- function(x, ...) {
  cat("<sciModelFlowR ReleaseCandidateAudit>\n")
  cat("  exports: ", x@n_exports, "\n", sep="")
  cat("  runtime certified: ", x@runtime_certified, "\n", sep="")
  cat("  status: ", x@status, "\n", sep="")
  invisible(x)
}
