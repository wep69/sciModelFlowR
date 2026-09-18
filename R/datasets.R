.smf_gold_names <- c("gold_linear_regression","gold_heteroscedastic_regression","gold_binary_calibration","gold_multiclass_imbalanced","gold_grouped_fields","gold_hierarchical_yield","gold_time_climate","gold_spatial_soil","gold_spectral_curve","gold_hyperspectral_small","gold_rgb_leaf_small","gold_multimodal_stress","gold_count_pests","gold_nonlinear_bart","gold_gp_surface","gold_distributional_yield","gold_covariate_shift","gold_missingness_mcar_mar","gold_conformal_heteroscedastic","gold_dl_tiny","gold_xai_stability","gold_dl_nonlinear","gold_dl_sequence","gold_bayesian_linear","gold_conformal_regression")

#' List frozen teaching and validation datasets
#' @export
smf_list_datasets <- function() .smf_gold_names

#' Load a frozen Gold dataset
#' @export
smf_load_dataset <- function(name) {
  name <- match.arg(name,.smf_gold_names)
  path <- system.file("extdata","gold",paste0(name,".csv"),package="sciModelFlowR")
  if(!nzchar(path)) {
    # development fallback when sourced outside an installed package
    path <- file.path("inst","extdata","gold",paste0(name,".csv"))
  }
  utils::read.csv(path,check.names=FALSE,stringsAsFactors=FALSE)
}

#' Read a Gold dataset card
#' @export
smf_dataset_card <- function(name) {
  name <- match.arg(name,.smf_gold_names)
  path <- system.file("gold","cards",paste0(name,".md"),package="sciModelFlowR")
  if(!nzchar(path)) path <- file.path("inst","gold","cards",paste0(name,".md"))
  paste(readLines(path,warn=FALSE,encoding="UTF-8"),collapse="\n")
}
