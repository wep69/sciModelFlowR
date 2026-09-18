.smf_sort_list <- function(x) {
  if (is.list(x)) {
    if (!is.null(names(x))) x <- x[order(names(x))]
    x <- lapply(x, .smf_sort_list)
  }
  x
}

#' Convert package objects to portable lists
#' @export
smf_to_list <- function(x) {
  if (.smf_is_s7(x)) {
    vals <- lapply(S7::props(x), smf_to_list)
    return(c(list(`__class__`=S7::S7_class(x)@name), vals))
  }
  if (is.list(x)) return(lapply(x, smf_to_list))
  if (is.data.frame(x)) return(x)
  x
}

.smf_class_map <- function(name) {
  switch(name,
    DataSpec=DataSpec, TaskSpec=TaskSpec, DesignSpec=DesignSpec, PreprocessSpec=PreprocessSpec,
    ResamplingSpec=ResamplingSpec, BootstrapSpec=BootstrapSpec, FeatureSpec=FeatureSpec, ModelSpec=ModelSpec,
    ProbabilisticSpec=ProbabilisticSpec, CalibrationSpec=CalibrationSpec, ImbalanceSpec=ImbalanceSpec, ReportingSpec=ReportingSpec, BayesianSpec=BayesianSpec,
    DeepLearningSpec=DeepLearningSpec, MetricSpec=MetricSpec, ConformalSpec=ConformalSpec, UncertaintySpec=UncertaintySpec,
    ReproducibilitySpec=ReproducibilitySpec, ExplainSpec=ExplainSpec, SearchSpace=SearchSpace, TuningSpec=TuningSpec, BenchmarkSpec=BenchmarkSpec, ExperimentSpec=ExperimentSpec,
    WarningRecord=WarningRecord, CapabilitySet=CapabilitySet, ResultMeta=ResultMeta,
    DataAuditResult=DataAuditResult, SplitRecord=SplitRecord, Preprocessor=Preprocessor,
    FitResult=FitResult, PredictionResult=PredictionResult, DiagnosticResult=DiagnosticResult,
    UncertaintyDescriptor=UncertaintyDescriptor, PredictionDistribution=PredictionDistribution,
    CalibrationResult=CalibrationResult, ImbalanceResult=ImbalanceResult, RunManifest=RunManifest, ResampleCollection=ResampleCollection, ResampleResult=ResampleResult, BootstrapResult=BootstrapResult,
    FeatureSelectionResult=FeatureSelectionResult, RepresentationResult=RepresentationResult,
    TuningResult=TuningResult, NestedTuningResult=NestedTuningResult, BenchmarkResult=BenchmarkResult, ExplainResult=ExplainResult, ExplanationStabilityResult=ExplanationStabilityResult,
    DLArchitecture=DLArchitecture, DLHistory=DLHistory, DLCheckpoint=DLCheckpoint, DLFitResult=DLFitResult,
    DLEnsembleResult=DLEnsembleResult, DLUncertaintyResult=DLUncertaintyResult, DLGradientExplanation=DLGradientExplanation,
    BayesFitResult=BayesFitResult, BayesianDiagnosticResult=BayesianDiagnosticResult, ConformalResult=ConformalResult, UncertaintyDecomposition=UncertaintyDecomposition,
    GPFitResult=GPFitResult, BARTFitResult=BARTFitResult,
    TrackingSpec=TrackingSpec, PersistenceSpec=PersistenceSpec, DeploymentSpec=DeploymentSpec, ScalabilitySpec=ScalabilitySpec,
    TrackerRun=TrackerRun, BundleValidationResult=BundleValidationResult, InferenceBundle=InferenceBundle, BatchPredictionResult=BatchPredictionResult,
    ExperimentResult=ExperimentResult,
    NULL)
}

#' Reconstruct package objects from portable lists
#' @export
smf_from_list <- function(x) {
  if (is.data.frame(x)) return(x)
  if (!is.list(x)) return(x)
  cls <- x[["__class__"]]
  if (!is.null(cls)) {
    x[["__class__"]] <- NULL
    x <- lapply(x, smf_from_list)
    # Backward-compatible defaults for 0.1.0 portable schemas.
    if (identical(cls, "ResamplingSpec") && is.null(x$parameters)) x$parameters <- list()
    if (identical(cls, "BootstrapSpec") && is.null(x$parameters)) x$parameters <- list()
    if (identical(cls, "ExperimentSpec") && is.null(x$features)) x$features <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$calibration)) x$calibration <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$imbalance)) x$imbalance <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$tuning)) x$tuning <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$benchmark)) x$benchmark <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$explain)) x$explain <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$conformal)) x$conformal <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$reporting)) x$reporting <- smf_reporting_spec()
    if (identical(cls, "ExperimentSpec") && is.null(x$tracking)) x$tracking <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$persistence)) x$persistence <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$deployment)) x$deployment <- NULL
    if (identical(cls, "ExperimentSpec") && is.null(x$scalability)) x$scalability <- NULL
    if (identical(cls, "RunManifest") && is.null(x$hardware)) x$hardware <- list()
    if (identical(cls, "PredictionResult") && is.null(x$probabilities)) x$probabilities <- NULL
    if (identical(cls, "PredictionResult") && is.null(x$distribution)) x$distribution <- NULL
    if (identical(cls, "PredictionResult") && is.null(x$calibration)) x$calibration <- NULL
    ctor <- .smf_class_map(cls)
    if (is.null(ctor)) cli::cli_abort("Unknown serialized class {.val {cls}}.")
    return(do.call(ctor, x))
  }
  lapply(x, smf_from_list)
}

#' Serialize to JSON
#' @export
smf_to_json <- function(x, pretty=TRUE) {
  jsonlite::toJSON(.smf_sort_list(smf_to_list(x)), auto_unbox=TRUE, null="null", digits=NA, pretty=pretty, dataframe="columns")
}

#' Serialize to YAML
#' @export
smf_to_yaml <- function(x) yaml::as.yaml(.smf_sort_list(smf_to_list(x)))

#' Read a package object from JSON
#' @export
smf_from_json <- function(x) {
  txt <- if (length(x)==1L && file.exists(x)) paste(readLines(x, warn=FALSE, encoding="UTF-8"), collapse="\n") else x
  smf_from_list(jsonlite::fromJSON(txt, simplifyVector=TRUE, simplifyDataFrame=FALSE, simplifyMatrix=FALSE))
}

#' Compute a canonical package hash
#' @export
smf_hash <- function(x, algo="sha256") digest::digest(smf_to_json(x, pretty=FALSE), algo=algo, serialize=FALSE)

#' Hash data deterministically
#' @export
smf_data_hash <- function(data, algo="sha256") {
  stopifnot(is.data.frame(data))
  tmp <- data
  tmp[] <- lapply(tmp, function(z) if (is.factor(z)) as.character(z) else z)
  digest::digest(tmp, algo=algo, serialize=TRUE)
}

#' Hash an experiment specification
#' @export
smf_spec_hash <- function(spec) smf_hash(spec)
