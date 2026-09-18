# Distribution-free conformal prediction with explicit scientific assumptions.

ConformalResult <- S7::new_class(
  "ConformalResult",
  properties = list(spec=S7::class_any, task=S7::class_character,
    state=S7::class_any, warnings=S7::class_any, provenance=S7::class_any)
)

.smf_conformal_quantile <- function(scores, level) {
  scores<-sort(as.numeric(scores)[is.finite(scores)])
  n<-length(scores); if(n<2L) cli::cli_abort("At least two finite calibration scores are required.")
  k<-min(n,ceiling((n+1)*level)); scores[[k]]
}

.smf_conformal_warnings <- function(spec, design=NULL) {
  out<-list()
  if(!is.null(design) && S7::S7_inherits(design,DesignSpec) && identical(spec@exchangeability,"iid")) {
    structured<-length(design@group_columns)||length(design@repeated_unit)||length(design@time_column)||length(design@coordinate_columns)
    if(structured) out[[length(out)+1L]]<-smf_warning_record("CONFORMAL_EXCHANGEABILITY_MISMATCH","IID conformal coverage was requested for data with declared grouping, repeated, temporal, or spatial structure.","high",evidence=list(exchangeability=spec@exchangeability),suggested_action="Use a calibration/resampling unit compatible with the dependence structure; ordinary marginal IID guarantees do not automatically transfer.")
  }
  if(spec@exchangeability %in% c("time","spatial","custom")) out[[length(out)+1L]]<-smf_warning_record("CONFORMAL_DEPENDENCE_GUARANTEE","Coverage under dependent calibration schemes depends on the selected conformal construction and assumptions; sciModelFlowR does not relabel IID guarantees as dependent-data guarantees.","warning",evidence=list(exchangeability=spec@exchangeability),override_allowed=TRUE)
  out
}

.smf_check_conformal_overlap <- function(calibration_ids, final_test_ids) {
  if(!is.null(calibration_ids) && !is.null(final_test_ids)) {
    ov<-intersect(as.character(calibration_ids),as.character(final_test_ids))
    if(length(ov)) .smf_abort("CONFORMAL_TEST_OVERLAP","Calibration and final-test IDs overlap. Final test data cannot calibrate conformal intervals or sets.",evidence=list(n_overlap=length(ov),ids=head(ov,20)),class="smf_leakage_error")
  }
  invisible(TRUE)
}

.smf_aps_scores <- function(truth, probabilities) {
  p<-as.matrix(probabilities); if(is.null(colnames(p))) cli::cli_abort("Classification probabilities must have class-name columns.")
  rs<-rowSums(p); if(any(!is.finite(rs)|rs<=0)) cli::cli_abort("Probability rows must have positive finite mass."); p<-p/rs
  truth<-as.character(truth); idx<-match(truth,colnames(p)); if(anyNA(idx)) cli::cli_abort("Truth contains labels absent from probability columns.")
  out<-numeric(nrow(p))
  for(i in seq_len(nrow(p))) { ord<-order(p[i,],decreasing=TRUE); cum<-cumsum(p[i,ord]); pos<-match(idx[i],ord); out[i]<-cum[pos] }
  out
}

#' Fit a package-native conformal calibrator
#' @export
smf_conformal_fit <- function(truth, prediction=NULL, spec=smf_conformal_spec(), design=NULL,
  fold_id=NULL, lower=NULL, upper=NULL, probabilities=NULL,
  calibration_ids=NULL, final_test_ids=NULL) {
  if(!S7::S7_inherits(spec,ConformalSpec)) cli::cli_abort("{.arg spec} must be a ConformalSpec.")
  .smf_check_conformal_overlap(calibration_ids,final_test_ids); warnings<-.smf_conformal_warnings(spec,design)
  score <- spec@score
  if (identical(score, "auto")) score <- switch(spec@method, split="absolute", cv_plus="absolute", quantile="quantile_residual", aps="aps_cumulative", full="absolute")
  allowed_score <- switch(spec@method, split="absolute", cv_plus="absolute", quantile="quantile_residual", aps="aps_cumulative", full="absolute")
  if (!identical(score, allowed_score)) .smf_abort("CONFORMAL_SCORE_UNSUPPORTED", paste0("Score '", score, "' is not implemented for method '", spec@method, "' in the package-native conformal engine."), class="smf_capability_error")
  if (identical(spec@method, "aps") && isTRUE(spec@randomized)) .smf_abort("CONFORMAL_RANDOMIZED_APS_NOT_IMPLEMENTED", "Randomized APS is not yet implemented in the package-native engine. Use deterministic APS or a certified backend.", class="smf_capability_error")
  y<-truth
  if(spec@method=="full") .smf_abort("CONFORMAL_FULL_REQUIRES_REFIT_ADAPTER","Full conformal inference requires model refitting for candidate outcomes. Use {.fn smf_conformal_probably} with a compatible workflow backend.",class="smf_capability_error")
  if(spec@method=="aps") {
    if(is.null(probabilities)) cli::cli_abort("{.arg probabilities} is required for APS classification sets.")
    scores<-.smf_aps_scores(y,probabilities); qhat<-.smf_conformal_quantile(scores,spec@level)
    return(ConformalResult(spec=spec,task="classification",state=list(qhat=qhat,scores=scores,classes=colnames(as.matrix(probabilities)),n=length(scores)),warnings=warnings,
      provenance=list(guarantee="marginal coverage under exchangeability",method="deterministic_APS",final_test_used=FALSE)))
  }
  y<-as.numeric(y)
  if(spec@method=="quantile") {
    if(is.null(lower)||is.null(upper)) cli::cli_abort("{.arg lower} and {.arg upper} are required for conformalized quantile intervals.")
    lo<-as.numeric(lower); hi<-as.numeric(upper); if(length(lo)!=length(y)||length(hi)!=length(y)) cli::cli_abort("Quantile predictions must match truth length.")
    scores<-pmax(lo-y,y-hi); qhat<-.smf_conformal_quantile(scores,spec@level)
    return(ConformalResult(spec=spec,task="regression",state=list(qhat=qhat,scores=scores,n=length(scores)),warnings=warnings,
      provenance=list(guarantee="marginal coverage under exchangeability",method="conformalized_quantile",final_test_used=FALSE)))
  }
  if(is.null(prediction)) cli::cli_abort("{.arg prediction} is required for regression conformal calibration.")
  pred<-as.numeric(prediction); if(length(pred)!=length(y)) cli::cli_abort("Prediction length must match truth length.")
  scores<-abs(y-pred)
  if(spec@method=="split") {
    qhat<-.smf_conformal_quantile(scores,spec@level)
    return(ConformalResult(spec=spec,task="regression",state=list(qhat=qhat,scores=scores,n=length(scores)),warnings=warnings,
      provenance=list(guarantee="marginal coverage under exchangeability",method="split_conformal_absolute_residual",final_test_used=FALSE)))
  }
  if(spec@method=="cv_plus") {
    if(is.null(fold_id) || length(fold_id)!=length(y)) cli::cli_abort("{.arg fold_id} must identify the out-of-fold prediction source for every calibration row.")
    return(ConformalResult(spec=spec,task="regression",state=list(scores=scores,fold_id=as.character(fold_id),fold_levels=unique(as.character(fold_id)),n=length(scores)),warnings=warnings,
      provenance=list(guarantee="CV+ marginal coverage for supported V-fold construction",method="cv_plus",final_test_used=FALSE)))
  }
  .smf_abort("CONFORMAL_METHOD_NOT_NATIVE","The requested method is not available in the package-native conformal engine.",class="smf_capability_error")
}

#' Predict conformal intervals or classification sets
#' @export
smf_conformal_predict <- function(object, prediction=NULL, fold_predictions=NULL, lower=NULL, upper=NULL, probabilities=NULL) {
  if(!S7::S7_inherits(object,ConformalResult)) cli::cli_abort("{.arg object} must be a ConformalResult.")
  method<-object@spec@method
  if(method=="split") { p<-as.numeric(prediction); q<-object@state$qhat; return(data.frame(.pred=p,.pred_lower=p-q,.pred_upper=p+q,interval_type="conformal",level=object@spec@level)) }
  if(method=="quantile") { lo<-as.numeric(lower); hi<-as.numeric(upper); if(length(lo)!=length(hi)) cli::cli_abort("Lower and upper predictions must have equal length."); q<-object@state$qhat; return(data.frame(.pred_lower=lo-q,.pred_upper=hi+q,interval_type="conformal_quantile",level=object@spec@level)) }
  if(method=="cv_plus") {
    fp<-as.matrix(fold_predictions); lev<-object@state$fold_levels
    if(is.null(colnames(fp))) { if(ncol(fp)!=length(lev)) cli::cli_abort("Fold-prediction matrix must have one column per calibration fold."); colnames(fp)<-lev }
    miss<-setdiff(lev,colnames(fp)); if(length(miss)) cli::cli_abort("Fold predictions are missing folds: {paste(miss,collapse=', ')}")
    fold_idx<-match(object@state$fold_id,lev); a<-(1-object@spec@level)/2; out<-matrix(NA_real_,nrow(fp),3L); colnames(out)<-c(".pred_lower",".pred",".pred_upper")
    for(j in seq_len(nrow(fp))) { base<-fp[j,lev]; center<-mean(base); lo<-base[fold_idx]-object@state$scores; hi<-base[fold_idx]+object@state$scores; out[j,]<-c(stats::quantile(lo,a,type=1,names=FALSE),center,stats::quantile(hi,1-a,type=1,names=FALSE)) }
    return(data.frame(out,interval_type="conformal_cv_plus",level=object@spec@level,check.names=FALSE))
  }
  if(method=="aps") {
    p<-as.matrix(probabilities); if(is.null(colnames(p))) cli::cli_abort("Probabilities require class-name columns."); p<-p/rowSums(p); sets<-vector("list",nrow(p)); logical_sets<-matrix(FALSE,nrow(p),ncol(p),dimnames=list(NULL,colnames(p)))
    for(i in seq_len(nrow(p))) { ord<-order(p[i,],decreasing=TRUE); cum<-cumsum(p[i,ord]); k<-which(cum>=object@state$qhat)[1L]; if(is.na(k)) k<-length(ord); keep<-ord[seq_len(k)]; logical_sets[i,keep]<-TRUE; sets[[i]]<-colnames(p)[keep] }
    return(list(sets=sets,membership=logical_sets,set_size=rowSums(logical_sets),level=object@spec@level,interval_type="conformal_prediction_set"))
  }
  .smf_abort("CONFORMAL_PREDICT_UNSUPPORTED","Prediction is not implemented for this conformal method.",class="smf_capability_error")
}

#' Estimate empirical conformal coverage
#' @export
smf_conformal_coverage <- function(truth, prediction) {
  if(is.data.frame(prediction) && all(c(".pred_lower",".pred_upper") %in% names(prediction))) {
    y<-as.numeric(truth); if(length(y)!=nrow(prediction)) cli::cli_abort("Truth length must match interval rows.")
    covered<-y>=prediction$.pred_lower & y<=prediction$.pred_upper
    return(data.frame(n=length(y),coverage=mean(covered),mean_width=mean(prediction$.pred_upper-prediction$.pred_lower),median_width=stats::median(prediction$.pred_upper-prediction$.pred_lower)))
  }
  if(is.list(prediction) && !is.null(prediction$sets)) {
    y<-as.character(truth); if(length(y)!=length(prediction$sets)) cli::cli_abort("Truth length must match prediction sets.")
    covered<-mapply(function(a,b) a %in% b,y,prediction$sets); return(data.frame(n=length(y),coverage=mean(covered),mean_set_size=mean(prediction$set_size),median_set_size=stats::median(prediction$set_size)))
  }
  cli::cli_abort("{.arg prediction} must contain conformal intervals or sets.")
}

#' Diagnose observed conformal coverage
#' @export
smf_conformal_diagnose <- function(object, truth, prediction, tolerance=NULL) {
  if(!S7::S7_inherits(object,ConformalResult)) cli::cli_abort("{.arg object} must be a ConformalResult.")
  cv<-smf_conformal_coverage(truth,prediction); n<-cv$n[[1]]; target<-object@spec@level; se<-sqrt(target*(1-target)/n); tol<-tolerance %||% max(0.01,2*se); warnings<-object@warnings
  if(cv$coverage[[1]] < target-tol) warnings[[length(warnings)+1L]]<-smf_warning_record("CONFORMAL_UNDERCOVERAGE","Observed conformal coverage is below the declared target beyond the diagnostic tolerance.","high",evidence=list(observed=cv$coverage[[1]],target=target,tolerance=tol,n=n),suggested_action="Check exchangeability, calibration size, score construction, and whether the evaluation set was untouched.")
  list(target=target,observed=cv$coverage[[1]],monte_carlo_se=se,tolerance=tol,summary=cv,warnings=warnings,guarantee=object@provenance$guarantee)
}

#' Use tidymodels probably conformal adapters
#' @export
smf_conformal_probably <- function(object, method=c("split","cv_plus","full","quantile"), cal_data=NULL, train_data=NULL, level=0.95, ...) {
  if(!.smf_package_available("probably")) .smf_abort("CONFORMAL_BACKEND_UNAVAILABLE","Package probably is required for this conformal adapter.",class="smf_capability_error")
  method<-match.arg(method)
  backend_object<-switch(method,
    split=probably::int_conformal_split(object,cal_data=cal_data,...),
    cv_plus=probably::int_conformal_cv(object,...),
    full=probably::int_conformal_full(object,train_data=train_data,...),
    quantile=probably::int_conformal_quantile(object,train_data=train_data,cal_data=cal_data,level=level,...))
  spec<-smf_conformal_spec(method=method,level=level,calibration_role=if(method=="cv_plus")"out_of_fold" else "calibration")
  ConformalResult(spec=spec,task="regression",state=list(backend_object=backend_object),warnings=list(),provenance=list(backend="probably",guarantee="as documented by backend method",final_test_used=FALSE))
}

#' Predict with a probably conformal adapter result
#' @export
smf_conformal_predict_probably <- function(object, new_data, level=NULL, ...) {
  if(!S7::S7_inherits(object,ConformalResult) || is.null(object@state$backend_object)) cli::cli_abort("{.arg object} must be a probably-backed ConformalResult.")
  lev<-level %||% object@spec@level
  if (identical(object@spec@method, "quantile")) return(stats::predict(object@state$backend_object,new_data=new_data,...))
  stats::predict(object@state$backend_object,new_data=new_data,level=lev,...)
}

S7::method(print, ConformalResult) <- function(x, ...) { cat("<sciModelFlowR ConformalResult>\n  method: ",x@spec@method,"\n  target coverage: ",x@spec@level,"\n  guarantee: ",x@provenance$guarantee,"\n",sep=""); invisible(x) }
