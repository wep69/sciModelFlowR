# Explanation stability across design-aware resamples and seeds (0.5.0).

.smf_rank_table <- function(tab) {
  z<-tab; z$rank<-rank(-z$importance,ties.method="average",na.last="keep"); z
}

#' Compare agreement between explanation tables
#' @export
smf_explanation_agreement <- function(explanations, top_k=5L) {
  if(!is.list(explanations)||length(explanations)<2L).smf_abort("EXPLANATION_LIST_REQUIRED","At least two explanation tables are required.",class="smf_explain_error")
  nms<-names(explanations); if(is.null(nms))nms<-paste0("explanation_",seq_along(explanations))
  rows<-list();k<-0L
  for(i in seq_len(length(explanations)-1L))for(j in (i+1L):length(explanations)) {
    a<-.smf_rank_table(explanations[[i]]); b<-.smf_rank_table(explanations[[j]]); common<-intersect(a$feature,b$feature)
    rho<-if(length(common)>1L)stats::cor(a$rank[match(common,a$feature)],b$rank[match(common,b$feature)],method="spearman",use="complete.obs")else NA_real_
    ta<-head(a$feature[order(a$rank)],top_k); tb<-head(b$feature[order(b$rank)],top_k); jac<-length(intersect(ta,tb))/length(union(ta,tb))
    k<-k+1L;rows[[k]]<-data.frame(a=nms[[i]],b=nms[[j]],spearman=rho,top_k=as.integer(top_k),topk_jaccard=jac,stringsAsFactors=FALSE)
  }
  do.call(rbind,rows)
}

#' Quantify permutation-importance stability across design-aware resamples
#' @export
smf_explanation_stability <- function(spec, data, explain=smf_explain_spec("permutation"), resamples=NULL, top_k=5L, override=FALSE) {
  if(!S7::S7_inherits(spec,ExperimentSpec)).smf_abort("EXPERIMENT_SPEC_REQUIRED","spec must be an ExperimentSpec.",class="smf_explain_error")
  if(is.null(resamples))resamples<-smf_make_resampler(data,explain@stability_resampling %||% spec@resampling,spec@design,spec@task,override)
  if(!S7::S7_inherits(resamples,ResampleCollection)).smf_abort("RESAMPLE_COLLECTION_REQUIRED","Explanation stability requires a ResampleCollection.",class="smf_explain_error")
  if(identical(resamples@method,"external")).smf_abort("EXTERNAL_TEST_IN_EXPLANATION_STABILITY","Final external test data cannot be repeatedly consumed for explanation stability estimation.",class="smf_leakage_error")
  method<-explain@methods[[1L]]; if(method!="permutation").smf_abort("STABILITY_METHOD_UNSUPPORTED","0.5.0 package-native stability currently standardizes permutation importance; SHAP/PDP/ALE can be compared separately with smf_explanation_agreement().",class="smf_capability_error")
  folds<-list(); all<-list()
  for(i in seq_along(resamples@splits)) {
    sp<-resamples@splits[[i]]; tr<-data[sp@train_index,,drop=FALSE]; te<-data[sp@test_index,,drop=FALSE]
    # Fit only on training partition; evaluate explanation only on assessment partition.
    core<-.smf_fit_supervised_partition(spec,tr,te,calibration_data=NULL,seed=as.integer(explain@seed+i-1L))
    meta<-.smf_make_meta(tr,spec,sp,backend=spec@model@engine,warnings=list())
    fr<-FitResult(meta=meta,model_spec=spec@model,preprocessing=core$preprocessor,features=core$feature_result,training_summary=list(n=core$model_n,task_kind=spec@task@kind,class_levels=core$adapter_fit$class_levels,calibration=core$calibration),backend_object=core$adapter_fit,predictors=core$predictors,target=spec@task@target)
    metric<-explain@parameters$metric %||% if(spec@task@kind=="regression")smf_metric_spec("rmse") else smf_metric_spec("log_loss")
    imp<-smf_permutation_importance(fr,te,te[[spec@task@target]],metric,explain@features,explain@n_repeats,as.integer(explain@seed+i*1000L)); imp$fold_id<-sp@id
    folds[[i]]<-imp; all[[i]]<-imp
  }
  z<-do.call(rbind,all); features<-unique(z$feature)
  summary<-do.call(rbind,lapply(features,function(nm){q<-z[z$feature==nm,,drop=FALSE];data.frame(feature=nm,mean_importance=mean(q$importance,na.rm=TRUE),sd_importance=stats::sd(q$importance,na.rm=TRUE),cv_importance=if(abs(mean(q$importance,na.rm=TRUE))>0)stats::sd(q$importance,na.rm=TRUE)/abs(mean(q$importance,na.rm=TRUE))else NA_real_,positive_fraction=mean(q$importance>0,na.rm=TRUE),n_folds=length(unique(q$fold_id)),stringsAsFactors=FALSE)}))
  ranktabs<-lapply(folds,.smf_rank_table); names(ranktabs)<-vapply(resamples@splits,function(s)s@id,character(1)); agreement<-if(length(ranktabs)>1L)smf_explanation_agreement(ranktabs,top_k)else data.frame()
  rk<-do.call(rbind,lapply(features,function(nm){r<-vapply(ranktabs,function(q)q$rank[match(nm,q$feature)],numeric(1));data.frame(feature=nm,mean_rank=mean(r,na.rm=TRUE),sd_rank=stats::sd(r,na.rm=TRUE),stringsAsFactors=FALSE)}))
  topstab<-if(nrow(agreement))data.frame(mean_topk_jaccard=mean(agreement$topk_jaccard,na.rm=TRUE),sd_topk_jaccard=stats::sd(agreement$topk_jaccard,na.rm=TRUE),top_k=as.integer(top_k))else data.frame(mean_topk_jaccard=NA_real_,sd_topk_jaccard=NA_real_,top_k=as.integer(top_k))
  warns<-.smf_correlated_feature_warnings(data,if(length(explain@features))explain@features else .smf_explain_fit(fr)@preprocessing@state$predictors,explain@parameters$correlation_threshold %||% 0.8)
  ExplanationStabilityResult(spec=explain,method=method,resamples=resamples,fold_values=z,summary=summary,rank_stability=rk,topk_stability=topstab,warnings=warns,
    provenance=list(resampling_hash=resamples@manifest_hash,seed=explain@seed,non_causal=TRUE,final_test_used=FALSE))
}
