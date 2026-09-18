# Formal package-native classes. Complex properties use class_any deliberately;
# cross-field validity is enforced by class validators and public constructors.

DataSpec <- S7::new_class(
  "DataSpec",
  properties = list(
    target = S7::class_character,
    predictors = S7::class_character,
    id_column = S7::class_character,
    units = S7::class_any,
    categorical = S7::class_character,
    numeric = S7::class_character,
    missing_codes = S7::class_any
  ),
  validator = function(self) {
    problems <- character()
    if (length(self@target) < 1L || any(!nzchar(self@target))) problems <- c(problems, "@target must contain at least one non-empty name")
    if (length(intersect(self@target, self@predictors))) problems <- c(problems, "@target cannot also be listed in @predictors")
    if (length(self@id_column) > 1L) problems <- c(problems, "@id_column must have length 0 or 1")
    if (length(problems)) problems else NULL
  }
)

TaskSpec <- S7::new_class(
  "TaskSpec",
  properties = list(
    kind = S7::class_character,
    target = S7::class_character,
    positive_label = S7::class_any,
    objective = S7::class_character
  ),
  validator = function(self) {
    allowed <- c("regression", "binary", "multiclass", "multilabel", "multioutput_regression", "count")
    problems <- character()
    if (length(self@kind) != 1L || !self@kind %in% allowed) problems <- c(problems, "@kind is not a supported task kind")
    if (!length(self@target)) problems <- c(problems, "@target must contain at least one response name")
    if (length(problems)) problems else NULL
  }
)

DesignSpec <- S7::new_class(
  "DesignSpec",
  properties = list(
    id_column = S7::class_character,
    group_columns = S7::class_character,
    block_columns = S7::class_character,
    repeated_unit = S7::class_character,
    time_column = S7::class_character,
    coordinate_columns = S7::class_character,
    external_domain_column = S7::class_character,
    hierarchy = S7::class_any,
    experimental_unit = S7::class_character
  ),
  validator = function(self) {
    problems <- character()
    scalar_or_empty <- list(id_column=self@id_column, repeated_unit=self@repeated_unit,
      time_column=self@time_column, external_domain_column=self@external_domain_column,
      experimental_unit=self@experimental_unit)
    for (nm in names(scalar_or_empty)) if (length(scalar_or_empty[[nm]]) > 1L) problems <- c(problems, paste0("@", nm, " must have length 0 or 1"))
    if (length(self@coordinate_columns) && length(self@coordinate_columns) != 2L) problems <- c(problems, "@coordinate_columns must have length 0 or 2")
    if (length(problems)) problems else NULL
  }
)

PreprocessSpec <- S7::new_class(
  "PreprocessSpec",
  properties = list(
    impute_numeric = S7::class_character,
    center = S7::class_logical,
    scale = S7::class_logical,
    one_hot = S7::class_logical,
    transformations = S7::class_any
  ),
  validator = function(self) {
    problems <- character()
    if (length(self@impute_numeric) != 1L || !self@impute_numeric %in% c("none", "mean", "median")) problems <- c(problems, "@impute_numeric must be none, mean, or median")
    if (length(self@center) != 1L || length(self@scale) != 1L || length(self@one_hot) != 1L) problems <- c(problems, "logical preprocessing properties must have length 1")
    if (length(problems)) problems else NULL
  }
)

ResamplingSpec <- S7::new_class(
  "ResamplingSpec",
  properties = list(
    method = S7::class_character,
    train_prop = S7::class_numeric,
    strata = S7::class_character,
    n_splits = S7::class_integer,
    n_repeats = S7::class_integer,
    seed = S7::class_integer,
    inner = S7::class_any,
    parameters = S7::class_any
  ),
  validator = function(self) {
    allowed <- c("holdout", "stratified_holdout", "external", "kfold", "repeated_kfold", "group", "blocked", "time_series", "spatial", "nested", "monte_carlo")
    problems <- character()
    if (length(self@method) != 1L || !self@method %in% allowed) problems <- c(problems, "@method is not recognized")
    if (length(self@train_prop) != 1L || self@train_prop <= 0 || self@train_prop >= 1) problems <- c(problems, "@train_prop must lie strictly between 0 and 1")
    if (length(problems)) problems else NULL
  }
)

BootstrapSpec <- S7::new_class(
  "BootstrapSpec",
  properties = list(method=S7::class_character, n_resamples=S7::class_integer,
    sampling_unit=S7::class_character, block_length=S7::class_any,
    statistic=S7::class_any, interval=S7::class_character,
    level=S7::class_numeric, seed=S7::class_integer, parameters=S7::class_any),
  validator = function(self) {
    allowed <- c("case", "stratified", "residual", "parametric", "wild", "cluster", "hierarchical", "moving_block", "stationary_block", "spatial_block")
    if (length(self@method) != 1L || !self@method %in% allowed) return("@method is not a supported bootstrap scheme")
    if (length(self@level) != 1L || self@level <= 0 || self@level >= 1) return("@level must lie strictly between 0 and 1")
    NULL
  }
)

FeatureSpec <- S7::new_class(
  "FeatureSpec",
  properties = list(
    method = S7::class_character,
    n_features = S7::class_any,
    threshold = S7::class_numeric,
    supervised = S7::class_logical,
    representation = S7::class_character,
    parameters = S7::class_any
  ),
  validator = function(self) {
    allowed <- c("none", "nzv", "correlation", "vif", "mutual_information",
      "rfe", "sequential", "regularized", "tree", "stability", "pca", "pls")
    if (length(self@method) != 1L || !self@method %in% allowed) return("@method is not supported")
    if (length(self@threshold) != 1L || !is.finite(self@threshold)) return("@threshold must be finite")
    NULL
  }
)

ModelSpec <- S7::new_class(
  "ModelSpec",
  properties = list(family=S7::class_character, engine=S7::class_character,
    parameters=S7::class_any, seed=S7::class_integer),
  validator = function(self) {
    if (length(self@family) != 1L || !nzchar(self@family)) return("@family must be a non-empty scalar")
    if (length(self@engine) != 1L || !nzchar(self@engine)) return("@engine must be a non-empty scalar")
    NULL
  }
)

ProbabilisticSpec <- S7::new_class(
  "ProbabilisticSpec",
  properties = list(distribution=S7::class_character, quantiles=S7::class_numeric,
    objective=S7::class_character, scores=S7::class_character),
  validator = function(self) {
    problems <- character()
    if (length(self@quantiles) && any(!is.finite(self@quantiles) | self@quantiles <= 0 | self@quantiles >= 1))
      problems <- c(problems, "@quantiles must lie strictly between 0 and 1")
    if (length(self@distribution) > 1L) problems <- c(problems, "@distribution must have length 0 or 1")
    if (length(problems)) problems else NULL
  }
)

CalibrationSpec <- S7::new_class(
  "CalibrationSpec",
  properties = list(method=S7::class_character, source=S7::class_character,
    calibration_prop=S7::class_numeric, bins=S7::class_integer, parameters=S7::class_any),
  validator = function(self) {
    allowed <- c("none","platt","isotonic","multinomial","beta")
    if (length(self@method) != 1L || !self@method %in% allowed) return("@method is not supported")
    if (length(self@source) != 1L || !self@source %in% c("analysis_holdout","external_predictions")) return("@source is not supported")
    if (length(self@calibration_prop) != 1L || self@calibration_prop <= 0 || self@calibration_prop >= 0.5) return("@calibration_prop must be in (0, 0.5)")
    if (length(self@bins) != 1L || self@bins < 2L) return("@bins must be at least 2")
    NULL
  }
)

ImbalanceSpec <- S7::new_class(
  "ImbalanceSpec",
  properties = list(method=S7::class_character, ratio=S7::class_numeric,
    neighbors=S7::class_integer, threshold=S7::class_numeric, parameters=S7::class_any),
  validator = function(self) {
    allowed <- c("none","weights","downsample","upsample","smote","bsmote","smotenc","smoten")
    if (length(self@method) != 1L || !self@method %in% allowed) return("@method is not supported")
    if (length(self@ratio) != 1L || !is.finite(self@ratio) || self@ratio <= 0) return("@ratio must be positive")
    if (length(self@threshold) != 1L || self@threshold <= 0 || self@threshold >= 1) return("@threshold must lie strictly between 0 and 1")
    NULL
  }
)

ReportingSpec <- S7::new_class(
  "ReportingSpec",
  properties = list(sections=S7::class_character, formats=S7::class_character,
    include_manifest=S7::class_logical, include_warnings=S7::class_logical)
)

BayesianSpec <- S7::new_class(
  "BayesianSpec",
  properties = list(inference=S7::class_character, priors=S7::class_any,
    chains=S7::class_integer, draws=S7::class_integer, warmup=S7::class_integer,
    target_accept=S7::class_numeric, seed=S7::class_integer),
  validator = function(self) {
    if (length(self@inference) != 1L || !self@inference %in% c("nuts", "hmc", "mcmc", "vi", "svi", "laplace")) return("@inference is not supported")
    NULL
  }
)

DeepLearningSpec <- S7::new_class(
  "DeepLearningSpec",
  properties = list(architecture=S7::class_character, trainer=S7::class_character,
    optimizer=S7::class_character, scheduler=S7::class_character,
    precision=S7::class_character, device=S7::class_character,
    epochs=S7::class_integer, batch_size=S7::class_integer, seed=S7::class_integer)
)

MetricSpec <- S7::new_class(
  "MetricSpec",
  properties = list(name=S7::class_character, direction=S7::class_character,
    aggregation=S7::class_character, decision_role=S7::class_character),
  validator = function(self) {
    if (length(self@name) != 1L || !nzchar(self@name)) return("@name must be a non-empty scalar")
    if (length(self@direction) != 1L || !self@direction %in% c("minimize", "maximize", "none")) return("@direction must be minimize, maximize, or none")
    NULL
  }
)


ConformalSpec <- S7::new_class(
  "ConformalSpec",
  properties = list(method=S7::class_character, level=S7::class_numeric,
    score=S7::class_character, calibration_role=S7::class_character,
    exchangeability=S7::class_character, randomized=S7::class_logical,
    parameters=S7::class_any),
  validator = function(self) {
    methods <- c("split", "cv_plus", "full", "quantile", "aps")
    if (length(self@method) != 1L || !self@method %in% methods) return("@method is not supported")
    if (length(self@level) != 1L || !is.finite(self@level) || self@level <= 0 || self@level >= 1) return("@level must lie strictly between 0 and 1")
    if (length(self@calibration_role) != 1L || !self@calibration_role %in% c("calibration", "out_of_fold")) return("@calibration_role must be calibration or out_of_fold")
    if (length(self@exchangeability) != 1L || !self@exchangeability %in% c("iid", "group", "time", "spatial", "custom")) return("@exchangeability is not supported")
    NULL
  }
)

UncertaintySpec <- S7::new_class(
  "UncertaintySpec",
  properties = list(target=S7::class_character, methods=S7::class_character,
    level=S7::class_numeric),
  validator = function(self) {
    if (length(self@level) != 1L || self@level <= 0 || self@level >= 1) return("@level must lie strictly between 0 and 1")
    NULL
  }
)

ReproducibilitySpec <- S7::new_class(
  "ReproducibilitySpec",
  properties = list(seed=S7::class_integer, determinism=S7::class_character,
    hash_data=S7::class_logical, capture_environment=S7::class_logical)
)


ExplainSpec <- S7::new_class(
  "ExplainSpec",
  properties = list(methods=S7::class_character, scope=S7::class_character,
    features=S7::class_character, background=S7::class_character,
    n_repeats=S7::class_integer, grid_size=S7::class_integer,
    ice_n=S7::class_integer, stability_resampling=S7::class_any,
    seed=S7::class_integer, parameters=S7::class_any),
  validator = function(self) {
    allowed <- c("permutation","pdp","ice","ale","shap","local","counterfactual")
    if (!length(self@methods) || any(!self@methods %in% allowed)) return("@methods contains an unsupported explanation method")
    if (length(self@scope) != 1L || !self@scope %in% c("global","local","both")) return("@scope must be global, local, or both")
    if (length(self@n_repeats) != 1L || self@n_repeats < 1L) return("@n_repeats must be at least 1")
    if (length(self@grid_size) != 1L || self@grid_size < 2L) return("@grid_size must be at least 2")
    NULL
  }
)

ExperimentSpec <- S7::new_class(
  "ExperimentSpec",
  properties = list(task=S7::class_any, data=S7::class_any, design=S7::class_any,
    preprocessing=S7::class_any, resampling=S7::class_any, model=S7::class_any,
    metrics=S7::class_any, features=S7::class_any, bootstrap=S7::class_any, probabilistic=S7::class_any,
    calibration=S7::class_any, imbalance=S7::class_any, tuning=S7::class_any, benchmark=S7::class_any, explain=S7::class_any, reporting=S7::class_any,
    bayesian=S7::class_any, deep_learning=S7::class_any, conformal=S7::class_any,
    uncertainty=S7::class_any, tracking=S7::class_any, persistence=S7::class_any,
    deployment=S7::class_any, scalability=S7::class_any, reproducibility=S7::class_any),
  validator = function(self) {
    req <- list(task=self@task, data=self@data, design=self@design,
      preprocessing=self@preprocessing, resampling=self@resampling,
      model=self@model, reproducibility=self@reproducibility)
    missing <- names(req)[vapply(req, is.null, logical(1))]
    if (length(missing)) paste0("Required experiment components are NULL: ", paste(missing, collapse=", ")) else NULL
  }
)

WarningRecord <- S7::new_class(
  "WarningRecord",
  properties = list(code=S7::class_character, severity=S7::class_character,
    message=S7::class_character, evidence=S7::class_any,
    suggested_action=S7::class_character, override_allowed=S7::class_logical),
  validator = function(self) {
    if (length(self@severity) != 1L || !self@severity %in% c("info", "warning", "high", "blocking")) return("@severity is invalid")
    NULL
  }
)

CapabilitySet <- S7::new_class(
  "CapabilitySet",
  properties = list(regression=S7::class_logical, classification=S7::class_logical,
    multiclass=S7::class_logical, multioutput=S7::class_logical,
    sample_weights=S7::class_logical, probabilities=S7::class_logical,
    quantiles=S7::class_logical, distribution=S7::class_logical,
    bootstrap=S7::class_logical, posterior_sampling=S7::class_logical,
    variational_inference=S7::class_logical, conformal=S7::class_logical,
    gpu=S7::class_logical, explain_global=S7::class_logical,
    explain_local=S7::class_logical, safe_export=S7::class_logical)
)

ResultMeta <- S7::new_class(
  "ResultMeta",
  properties = list(run_id=S7::class_character, created_at=S7::class_character,
    package_version=S7::class_character, backend=S7::class_character,
    backend_version=S7::class_character, data_hash=S7::class_character,
    split_hash=S7::class_character, spec_hash=S7::class_character,
    seed=S7::class_integer, warnings=S7::class_any, provenance=S7::class_any)
)

DataAuditResult <- S7::new_class(
  "DataAuditResult",
  properties = list(meta=S7::class_any, schema=S7::class_any,
    missingness=S7::class_any, duplicates=S7::class_any,
    cardinality=S7::class_any, leakage=S7::class_any,
    quality_flags=S7::class_any)
)

SplitRecord <- S7::new_class(
  "SplitRecord",
  properties = list(id=S7::class_character, method=S7::class_character,
    train_index=S7::class_integer, validation_index=S7::class_integer,
    test_index=S7::class_integer, train_ids=S7::class_any,
    validation_ids=S7::class_any, test_ids=S7::class_any,
    seed=S7::class_integer, hash=S7::class_character, summary=S7::class_any)
)

Preprocessor <- S7::new_class(
  "Preprocessor",
  properties = list(spec=S7::class_any, data_spec=S7::class_any,
    training_hash=S7::class_character, state=S7::class_any,
    fitted=S7::class_logical)
)

FitResult <- S7::new_class(
  "FitResult",
  properties = list(meta=S7::class_any, model_spec=S7::class_any,
    preprocessing=S7::class_any, features=S7::class_any, training_summary=S7::class_any,
    backend_object=S7::class_any, predictors=S7::class_character,
    target=S7::class_character)
)

PredictionResult <- S7::new_class(
  "PredictionResult",
  properties = list(meta=S7::class_any, row_ids=S7::class_any,
    estimate=S7::class_any, truth=S7::class_any, probabilities=S7::class_any,
    response_scale=S7::class_character, intervals=S7::class_any,
    distribution=S7::class_any, calibration=S7::class_any)
)

DiagnosticResult <- S7::new_class(
  "DiagnosticResult",
  properties = list(meta=S7::class_any, checks=S7::class_any,
    residuals=S7::class_any, fitted=S7::class_any,
    evidence=S7::class_any, warnings=S7::class_any)
)

UncertaintyDescriptor <- S7::new_class(
  "UncertaintyDescriptor",
  properties = list(source=S7::class_character, target=S7::class_character,
    interval_type=S7::class_character, level=S7::class_numeric,
    conditional_on=S7::class_character)
)

PredictionDistribution <- S7::new_class(
  "PredictionDistribution",
  properties = list(representation=S7::class_character, payload=S7::class_any,
    uncertainty=S7::class_any, capabilities=S7::class_any),
  validator = function(self) {
    allowed <- c("point","class_probabilities","samples","quantiles","parametric","interval")
    if (length(self@representation) != 1L || !self@representation %in% allowed) return("@representation is not supported")
    NULL
  }
)

CalibrationResult <- S7::new_class(
  "CalibrationResult",
  properties = list(method=S7::class_character, source=S7::class_character, model=S7::class_any,
    class_levels=S7::class_character, positive_label=S7::class_any, training_hash=S7::class_character,
    n=S7::class_integer, diagnostics=S7::class_any, warnings=S7::class_any)
)

ImbalanceResult <- S7::new_class(
  "ImbalanceResult",
  properties = list(method=S7::class_character, data=S7::class_any, weights=S7::class_any,
    before=S7::class_any, after=S7::class_any, training_hash=S7::class_character, provenance=S7::class_any)
)

RunManifest <- S7::new_class(
  "RunManifest",
  properties = list(run_id=S7::class_character, created_at=S7::class_character,
    package_version=S7::class_character, R_version=S7::class_character,
    platform=S7::class_character, architecture=S7::class_character,
    dependency_versions=S7::class_any, backend=S7::class_character,
    backend_version=S7::class_character, rng_kind=S7::class_any,
    seed=S7::class_integer, data_hash=S7::class_character,
    schema_hash=S7::class_character, spec_hash=S7::class_character,
    split_hash=S7::class_character, preprocessing_hash=S7::class_character,
    model_spec=S7::class_any, metrics=S7::class_any, warnings=S7::class_any,
    hardware=S7::class_any, duration_seconds=S7::class_numeric)
)

ResampleCollection <- S7::new_class(
  "ResampleCollection",
  properties = list(method=S7::class_character, splits=S7::class_any, seed=S7::class_integer,
    source_spec=S7::class_any, design=S7::class_any, manifest_hash=S7::class_character,
    diagnostics=S7::class_any, nested=S7::class_any)
)

ResampleResult <- S7::new_class(
  "ResampleResult",
  properties = list(meta=S7::class_any, spec=S7::class_any, resamples=S7::class_any,
    fold_results=S7::class_any, metrics=S7::class_any, aggregate=S7::class_any,
    warnings=S7::class_any)
)

BootstrapResult <- S7::new_class(
  "BootstrapResult",
  properties = list(meta=S7::class_any, spec=S7::class_any, original=S7::class_any,
    estimates=S7::class_any, successful=S7::class_integer, failed=S7::class_integer,
    failures=S7::class_any, interval=S7::class_any, sampling_unit=S7::class_character,
    stability=S7::class_any)
)

FeatureSelectionResult <- S7::new_class(
  "FeatureSelectionResult",
  properties = list(spec=S7::class_any, selected=S7::class_character, scores=S7::class_any,
    fold_results=S7::class_any, stability=S7::class_any, provenance=S7::class_any,
    warnings=S7::class_any)
)

RepresentationResult <- S7::new_class(
  "RepresentationResult",
  properties = list(spec=S7::class_any, state=S7::class_any, transformed=S7::class_any,
    training_hash=S7::class_character, feature_map=S7::class_any)
)

ExperimentResult <- S7::new_class(
  "ExperimentResult",
  properties = list(meta=S7::class_any, spec=S7::class_any,
    audit=S7::class_any, split=S7::class_any, fit=S7::class_any,
    prediction=S7::class_any, diagnostics=S7::class_any,
    metrics=S7::class_any, manifest=S7::class_any)
)


SearchSpace <- S7::new_class(
  "SearchSpace",
  properties = list(parameters=S7::class_any, conditions=S7::class_any,
    metadata=S7::class_any),
  validator = function(self) {
    if (!is.list(self@parameters) || !length(self@parameters)) return("@parameters must be a non-empty named list")
    if (is.null(names(self@parameters)) || any(!nzchar(names(self@parameters))) || anyDuplicated(names(self@parameters))) return("@parameters must have unique non-empty names")
    bad <- vapply(self@parameters, function(z) !is.list(z) || is.null(z$type), logical(1))
    if (any(bad)) return("Every search-space parameter must be a parameter-domain list")
    NULL
  }
)

TuningSpec <- S7::new_class(
  "TuningSpec",
  properties = list(method=S7::class_character, budget=S7::class_integer,
    inner_resampling=S7::class_any, objectives=S7::class_any,
    backend=S7::class_character, seed=S7::class_integer,
    decision_rule=S7::class_any, parameters=S7::class_any),
  validator = function(self) {
    allowed <- c("grid","random","racing","bayesian","successive_halving","hyperband")
    if (length(self@method) != 1L || !self@method %in% allowed) return("@method is not supported")
    if (length(self@budget) != 1L || is.na(self@budget) || self@budget < 1L) return("@budget must be at least 1")
    if (length(self@backend) != 1L || !self@backend %in% c("native","mlr3")) return("@backend must be native or mlr3")
    NULL
  }
)

BenchmarkSpec <- S7::new_class(
  "BenchmarkSpec",
  properties = list(candidates=S7::class_any, metrics=S7::class_any,
    resampling=S7::class_any, decision_rule=S7::class_any,
    compute_measures=S7::class_character, repetitions=S7::class_integer,
    seed=S7::class_integer, parameters=S7::class_any),
  validator = function(self) {
    if (!is.list(self@candidates) || length(self@candidates) < 2L) return("@candidates must contain at least two model specifications")
    if (is.null(names(self@candidates)) || any(!nzchar(names(self@candidates))) || anyDuplicated(names(self@candidates))) return("@candidates must have unique non-empty names")
    if (length(self@repetitions) != 1L || self@repetitions < 1L) return("@repetitions must be at least 1")
    NULL
  }
)

TuningResult <- S7::new_class(
  "TuningResult",
  properties = list(spec=S7::class_any, search_space=S7::class_any,
    archive=S7::class_any, selected=S7::class_any, pareto=S7::class_any,
    decision_rule=S7::class_any, inner_resampling=S7::class_any,
    split_hashes=S7::class_any, warnings=S7::class_any,
    provenance=S7::class_any)
)

NestedTuningResult <- S7::new_class(
  "NestedTuningResult",
  properties = list(spec=S7::class_any, tuning=S7::class_any,
    search_space=S7::class_any, outer_resampling=S7::class_any,
    outer_results=S7::class_any, selection_scores=S7::class_any,
    generalization_scores=S7::class_any, split_hashes=S7::class_any,
    warnings=S7::class_any, provenance=S7::class_any)
)

BenchmarkResult <- S7::new_class(
  "BenchmarkResult",
  properties = list(spec=S7::class_any, benchmark_spec=S7::class_any,
    resamples=S7::class_any, performance=S7::class_any,
    summary=S7::class_any, uncertainty=S7::class_any,
    compute=S7::class_any, stability=S7::class_any,
    pareto=S7::class_any, decision=S7::class_any,
    warnings=S7::class_any, provenance=S7::class_any)
)


ExplainResult <- S7::new_class(
  "ExplainResult",
  properties = list(spec=S7::class_any, method=S7::class_character, scope=S7::class_character,
    values=S7::class_any, feature_map=S7::class_any, diagnostics=S7::class_any,
    causal_interpretation=S7::class_logical, warnings=S7::class_any, provenance=S7::class_any)
)

ExplanationStabilityResult <- S7::new_class(
  "ExplanationStabilityResult",
  properties = list(spec=S7::class_any, method=S7::class_character, resamples=S7::class_any,
    fold_values=S7::class_any, summary=S7::class_any, rank_stability=S7::class_any,
    topk_stability=S7::class_any, warnings=S7::class_any, provenance=S7::class_any)
)
