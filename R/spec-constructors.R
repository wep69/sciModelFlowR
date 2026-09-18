#' Create a data specification
#' @export
smf_data_spec <- function(target, predictors = character(), id_column = character(), units = list(), categorical = character(), numeric = character(), missing_codes = list()) {
  DataSpec(target=.smf_chr(target), predictors=.smf_chr(predictors), id_column=.smf_chr(id_column), units=units, categorical=.smf_chr(categorical), numeric=.smf_chr(numeric), missing_codes=missing_codes)
}

#' Create a task specification
#' @export
smf_task_spec <- function(kind = "regression", target, positive_label = NULL, objective = character()) {
  TaskSpec(kind=.smf_scalar_chr(kind,"kind"), target=.smf_chr(target), positive_label=positive_label, objective=.smf_chr(objective))
}

#' Create a scientific design specification
#' @export
smf_design_spec <- function(id_column=character(), group_columns=character(), block_columns=character(), repeated_unit=character(), time_column=character(), coordinate_columns=character(), external_domain_column=character(), hierarchy=list(), experimental_unit=character(), groups=NULL, blocks=NULL, time=NULL, coordinates=NULL) {
  if (!is.null(groups)) group_columns <- groups
  if (!is.null(blocks)) block_columns <- blocks
  if (!is.null(time)) time_column <- time
  if (!is.null(coordinates)) coordinate_columns <- coordinates
  DesignSpec(id_column=.smf_chr(id_column), group_columns=.smf_chr(group_columns), block_columns=.smf_chr(block_columns), repeated_unit=.smf_chr(repeated_unit), time_column=.smf_chr(time_column), coordinate_columns=.smf_chr(coordinate_columns), external_domain_column=.smf_chr(external_domain_column), hierarchy=hierarchy, experimental_unit=.smf_chr(experimental_unit))
}

#' Create a preprocessing specification
#' @export
smf_preprocess_spec <- function(impute_numeric=c("none","mean","median"), center=FALSE, scale=FALSE, one_hot=TRUE, transformations=list()) {
  impute_numeric <- match.arg(impute_numeric)
  PreprocessSpec(impute_numeric=impute_numeric, center=.smf_scalar_lgl(center,"center"), scale=.smf_scalar_lgl(scale,"scale"), one_hot=.smf_scalar_lgl(one_hot,"one_hot"), transformations=transformations)
}

#' Create a resampling specification
#' @export
smf_resampling_spec <- function(method=c("holdout","stratified_holdout","external","kfold","repeated_kfold","group","blocked","time_series","spatial","nested","monte_carlo"), train_prop=0.8, strata=character(), n_splits=5L, n_repeats=1L, seed=260915L, inner=NULL, parameters=list()) {
  method <- match.arg(method)
  ResamplingSpec(method=method, train_prop=as.numeric(train_prop), strata=.smf_chr(strata), n_splits=as.integer(n_splits), n_repeats=as.integer(n_repeats), seed=as.integer(seed), inner=inner, parameters=parameters)
}

#' Create a bootstrap specification
#' @export
smf_bootstrap_spec <- function(method=c("case","stratified","residual","parametric","wild","cluster","hierarchical","moving_block","stationary_block","spatial_block"), n_resamples=1999L, sampling_unit=character(), block_length=NULL, statistic="metric", interval=c("percentile","basic","bca","studentized"), level=0.95, seed=260915L, parameters=list()) {
  BootstrapSpec(method=match.arg(method), n_resamples=as.integer(n_resamples), sampling_unit=.smf_chr(sampling_unit), block_length=block_length, statistic=statistic, interval=match.arg(interval), level=as.numeric(level), seed=as.integer(seed), parameters=parameters)
}

#' Create a feature-selection or representation specification
#' @export
smf_feature_spec <- function(method=c("none","nzv","correlation","vif","mutual_information","rfe","sequential","regularized","tree","stability","pca","pls"), n_features=NULL, threshold=0.95, supervised=NULL, representation=character(), parameters=list()) {
  method <- match.arg(method)
  if (is.null(supervised)) supervised <- method %in% c("mutual_information","rfe","sequential","regularized","tree","stability","pls")
  FeatureSpec(method=method, n_features=n_features, threshold=as.numeric(threshold), supervised=.smf_scalar_lgl(supervised,"supervised"), representation=.smf_chr(representation), parameters=parameters)
}

#' Create a model specification
#' @export
smf_model_spec <- function(family, engine="stats", parameters=list(), seed=260915L) {
  ModelSpec(family=.smf_scalar_chr(family,"family"), engine=.smf_scalar_chr(engine,"engine"), parameters=parameters, seed=as.integer(seed))
}

#' Create a probabilistic-model specification
#' @export
smf_probabilistic_spec <- function(distribution=character(), quantiles=numeric(), objective=character(), scores=character()) {
  ProbabilisticSpec(distribution=.smf_chr(distribution), quantiles=sort(unique(as.numeric(quantiles))), objective=.smf_chr(objective), scores=.smf_chr(scores))
}

#' Create a probability calibration specification
#' @export
smf_calibration_spec <- function(method=c("none","platt","isotonic","multinomial","beta"), source=c("analysis_holdout","external_predictions"), calibration_prop=0.2, bins=10L, parameters=list()) {
  CalibrationSpec(method=match.arg(method), source=match.arg(source), calibration_prop=as.numeric(calibration_prop), bins=as.integer(bins), parameters=parameters)
}

#' Create a fold-safe class-imbalance specification
#' @export
smf_imbalance_spec <- function(method=c("none","weights","downsample","upsample","smote","bsmote","smotenc","smoten"), ratio=1, neighbors=5L, threshold=0.5, parameters=list()) {
  ImbalanceSpec(method=match.arg(method), ratio=as.numeric(ratio), neighbors=as.integer(neighbors), threshold=as.numeric(threshold), parameters=parameters)
}

#' Create the minimal reporting specification introduced in 0.3.0
#' @export
smf_reporting_spec <- function(sections=c("design","audit","performance","calibration","reproducibility"), formats="markdown", include_manifest=TRUE, include_warnings=TRUE) {
  ReportingSpec(sections=.smf_chr(sections), formats=.smf_chr(formats), include_manifest=.smf_scalar_lgl(include_manifest,"include_manifest"), include_warnings=.smf_scalar_lgl(include_warnings,"include_warnings"))
}

#' Create a Bayesian specification
#' @export
smf_bayesian_spec <- function(inference=c("nuts","hmc","mcmc","vi","svi","laplace"), priors=list(), chains=4L, draws=2000L, warmup=1000L, target_accept=0.9, seed=260915L) {
  BayesianSpec(inference=match.arg(inference), priors=priors, chains=as.integer(chains), draws=as.integer(draws), warmup=as.integer(warmup), target_accept=as.numeric(target_accept), seed=as.integer(seed))
}

#' Create a Deep Learning specification
#' @export
smf_dl_spec <- function(architecture=character(), trainer="torch", optimizer="adam", scheduler=character(), precision="float32", device="auto", epochs=100L, batch_size=32L, seed=260915L) {
  DeepLearningSpec(architecture=.smf_chr(architecture), trainer=.smf_chr(trainer), optimizer=.smf_chr(optimizer), scheduler=.smf_chr(scheduler), precision=.smf_chr(precision), device=.smf_chr(device), epochs=as.integer(epochs), batch_size=as.integer(batch_size), seed=as.integer(seed))
}

#' Create a metric specification
#' @export
smf_metric_spec <- function(name, direction=NULL, aggregation="mean", decision_role="evaluation") {
  name <- .smf_scalar_chr(name,"name")
  if (is.null(direction)) direction <- if (tolower(name) %in% c("rmse","mae","mse","log_loss","brier","nll","crps","interval_score","ece")) "minimize" else "maximize"
  MetricSpec(name=name, direction=.smf_scalar_chr(direction,"direction"), aggregation=.smf_scalar_chr(aggregation,"aggregation"), decision_role=.smf_scalar_chr(decision_role,"decision_role"))
}


#' Create a conformal-prediction specification
#' @export
smf_conformal_spec <- function(method=c("split","cv_plus","full","quantile","aps"), level=0.95, score="auto", calibration_role=c("calibration","out_of_fold"), exchangeability=c("iid","group","time","spatial","custom"), randomized=FALSE, parameters=list()) {
  method <- match.arg(method); calibration_role <- match.arg(calibration_role); exchangeability <- match.arg(exchangeability)
  ConformalSpec(method=method, level=.smf_scalar_num(level,"level",0,1,TRUE,TRUE), score=.smf_scalar_chr(score,"score"), calibration_role=calibration_role, exchangeability=exchangeability, randomized=.smf_scalar_lgl(randomized,"randomized"), parameters=parameters)
}

#' Create an uncertainty specification
#' @export
smf_uncertainty_spec <- function(target="prediction", methods=character(), level=0.95) {
  UncertaintySpec(target=.smf_scalar_chr(target,"target"), methods=.smf_chr(methods), level=as.numeric(level))
}

#' Create an explainability specification
#' @export
smf_explain_spec <- function(methods=c("permutation","pdp","ale"), scope=c("both","global","local"),
                             features=character(), background=c("training","assessment","explicit"),
                             n_repeats=20L, grid_size=20L, ice_n=50L, stability_resampling=NULL,
                             seed=260915L, parameters=list()) {
  scope <- match.arg(scope); background <- match.arg(background)
  ExplainSpec(methods=unique(.smf_chr(methods)), scope=scope, features=.smf_chr(features),
    background=background, n_repeats=as.integer(n_repeats), grid_size=as.integer(grid_size),
    ice_n=as.integer(ice_n), stability_resampling=stability_resampling, seed=as.integer(seed), parameters=parameters)
}

#' Create a reproducibility specification
#' @export
smf_reproducibility_spec <- function(seed=260915L, determinism="seed_deterministic_cpu", hash_data=TRUE, capture_environment=TRUE) {
  ReproducibilitySpec(seed=as.integer(seed), determinism=.smf_scalar_chr(determinism,"determinism"), hash_data=.smf_scalar_lgl(hash_data,"hash_data"), capture_environment=.smf_scalar_lgl(capture_environment,"capture_environment"))
}

#' Compose an experiment specification
#' @export
smf_experiment_spec <- function(task, data, design=smf_design_spec(), preprocessing=smf_preprocess_spec(), resampling=smf_resampling_spec(), model, metrics=list(smf_metric_spec("rmse")), features=NULL, bootstrap=NULL, probabilistic=NULL, calibration=NULL, imbalance=NULL, tuning=NULL, benchmark=NULL, explain=NULL, reporting=smf_reporting_spec(), bayesian=NULL, deep_learning=NULL, conformal=NULL, uncertainty=NULL, tracking=NULL, persistence=NULL, deployment=NULL, scalability=NULL, reproducibility=smf_reproducibility_spec()) {
  if (!is.list(metrics)) metrics <- list(metrics)
  ExperimentSpec(task=task, data=data, design=design, preprocessing=preprocessing, resampling=resampling, model=model, metrics=metrics, features=features, bootstrap=bootstrap, probabilistic=probabilistic, calibration=calibration, imbalance=imbalance, tuning=tuning, benchmark=benchmark, explain=explain, reporting=reporting, bayesian=bayesian, deep_learning=deep_learning, conformal=conformal, uncertainty=uncertainty, tracking=tracking, persistence=persistence, deployment=deployment, scalability=scalability, reproducibility=reproducibility)
}
