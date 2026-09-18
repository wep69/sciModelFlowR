# Probabilistic Deep Learning contracts introduced in 0.6.0.

#' Declare a probabilistic Deep Learning output head
#' @export
smf_dl_distributional_head <- function(distribution=c("gaussian","bernoulli","categorical"), parameters=list()) {
  distribution <- match.arg(distribution)
  constraints <- switch(distribution, gaussian=list(mu="real", sigma="positive_softplus"), bernoulli=list(prob="unit_interval_sigmoid"), categorical=list(prob="simplex_softmax"))
  list(distribution=distribution, constraints=constraints, parameters=parameters)
}

#' Draw Monte Carlo dropout predictions
#' @export
smf_dl_mc_dropout <- function(object, newdata, draws=100L, seed=260915L) {
  if (!S7::S7_inherits(object, DLFitResult)) cli::cli_abort("{.arg object} must be a DLFitResult.")
  if (draws < 2L) cli::cli_abort("{.arg draws} must be at least 2.")
  .smf_require_torch(); set.seed(as.integer(seed)); try(torch::torch_manual_seed(as.integer(seed)),silent=TRUE)
  object@model$train()
  sims <- replicate(as.integer(draws), drop(smf_dl_predict_tensor(object, newdata)))
  sims <- t(as.matrix(sims))
  smf_prediction_distribution("samples", payload=list(samples=sims),
    uncertainty=UncertaintyDescriptor(source="mc_dropout", target="prediction", interval_type="simulation", level=0.95, conditional_on="trained_network"))
}

#' Fit or combine a Deep Learning ensemble
#' @export
smf_dl_ensemble <- function(x=NULL, y=NULL, architecture=NULL, fits=NULL, seeds=c(260915L,260916L,260917L), ...) {
  seeds <- as.integer(seeds)
  if (anyDuplicated(seeds)) .smf_abort("ENSEMBLE_SEEDS_NOT_INDEPENDENT", "Deep-ensemble members must use distinct declared seeds.")
  if (is.null(fits)) {
    if (is.null(x) || is.null(y) || is.null(architecture)) cli::cli_abort("Supply either {.arg fits} or x, y, and architecture.")
    fits <- lapply(seeds, function(s) smf_dl_train_tensor(x,y,architecture=architecture,seed=s,...))
  }
  DLEnsembleResult(members=fits, seeds=seeds, predictions=NULL, distribution=NULL,
    provenance=list(method="independently_initialized_deep_ensemble", n_members=length(fits)))
}

#' Predict a distribution from a Deep Learning uncertainty method
#' @export
smf_dl_predict_distribution <- function(object, newdata, method=c("ensemble","mc_dropout","gaussian_head"), draws=100L, level=0.95) {
  method <- match.arg(method)
  if (method == "mc_dropout") return(smf_dl_mc_dropout(object,newdata,draws=draws))
  if (method == "ensemble") {
    if (!S7::S7_inherits(object,DLEnsembleResult)) cli::cli_abort("Ensemble prediction requires a DLEnsembleResult.")
    mat <- do.call(cbind,lapply(object@members,function(m) drop(smf_dl_predict_tensor(m,newdata))))
    return(smf_prediction_distribution("samples", payload=list(samples=t(mat)),
      uncertainty=UncertaintyDescriptor(source="deep_ensemble",target="prediction",interval_type="simulation",level=level,conditional_on="member_training")))
  }
  pred <- smf_dl_predict_tensor(object,newdata)
  if (ncol(as.matrix(pred)) < 2L) .smf_abort("GAUSSIAN_HEAD_SHAPE", "Gaussian distributional heads require at least two outputs: location and unconstrained scale.")
  p <- as.matrix(pred); sigma <- log1p(exp(p[,2L])) + 1e-6
  smf_prediction_distribution("parametric", payload=list(distribution="normal", mean=p[,1L], sd=sigma),
    uncertainty=UncertaintyDescriptor(source="distributional_head",target="prediction",interval_type="parametric",level=level,conditional_on="network_parameters"))
}

#' Extract predictive intervals from a Deep Learning distribution
#' @export
smf_dl_interval <- function(distribution, level=0.95) smf_dist_interval(distribution, level=level)

#' Decompose identifiable Deep Learning predictive uncertainty
#' @export
smf_dl_uncertainty_decompose <- function(distribution, aleatoric=NULL, level=0.95) {
  if (!S7::S7_inherits(distribution,PredictionDistribution)) cli::cli_abort("{.arg distribution} must be a PredictionDistribution.")
  if (distribution@representation != "samples") {
    if (distribution@representation == "parametric" && identical(distribution@payload$distribution,"normal")) {
      a <- distribution@payload$sd^2; e <- rep(0,length(a)); total <- a
    } else .smf_abort("UNCERTAINTY_NOT_IDENTIFIABLE", "Aleatoric and epistemic components are not identifiable from this predictive representation.")
  } else {
    s <- as.matrix(distribution@payload$samples); total <- apply(s,2L,stats::var)
    if (is.null(aleatoric)) .smf_abort("UNCERTAINTY_NOT_IDENTIFIABLE", "Sample variability alone does not identify aleatoric versus epistemic uncertainty; supply a model-based aleatoric component.")
    a <- rep_len(as.numeric(aleatoric),length(total)); e <- pmax(total-a,0)
  }
  DLUncertaintyResult(mean=smf_dist_mean(distribution), aleatoric=a, epistemic=e, total=total,
    intervals=smf_dist_interval(distribution,level=level),
    descriptor=UncertaintyDescriptor(source="deep_learning_decomposition",target="prediction",interval_type="variance_decomposition",level=level,conditional_on="model_structure"),
    provenance=list(identified=TRUE))
}
