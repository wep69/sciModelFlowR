.smf_fit_one_split <- function(spec,data,split) {
  train<-data[split@train_index,,drop=FALSE]; test<-data[split@test_index,,drop=FALSE]
  core<-.smf_fit_supervised_partition(spec,train,test,calibration_data=NULL,seed=split@seed+as.integer(sum(split@test_index)%%100000L))
  list(split=split,preprocessor=core$preprocessor,feature_result=core$feature_result,imbalance=core$imbalance,fit=core$adapter_fit,calibration=core$calibration,prediction=core$estimate,probabilities=core$probabilities,distribution=core$distribution,truth=core$truth,metrics=core$metrics)
}

#' Fit a supervised experiment independently across design-aware resamples
#' @export
smf_resample_experiment <- function(spec,data,resamples=NULL,override=FALSE) {
  smf_validate_schema(data,spec@data)
  if(is.null(resamples)) resamples<-smf_make_resampler(data,spec@resampling,spec@design,spec@task,override=override)
  if(!S7::S7_inherits(resamples,ResampleCollection)) cli::cli_abort("{.arg resamples} must be a ResampleCollection.")
  smf_require_capability(spec@model@engine,.smf_task_capability(spec@task))
  fold_results<-lapply(resamples@splits,function(s).smf_fit_one_split(spec,data,s))
  metric_rows<-do.call(rbind,lapply(seq_along(fold_results),function(i){z<-fold_results[[i]]$metrics;z$fold<-i;z$split_id<-fold_results[[i]]$split@id;z}))
  group_cols<-intersect(c("metric","target"),names(metric_rows)); key<-interaction(metric_rows[group_cols],drop=TRUE,lex.order=TRUE)
  agg<-do.call(rbind,lapply(split(metric_rows,key),function(z){base<-data.frame(metric=z$metric[[1]],mean=mean(z$value,na.rm=TRUE),sd=stats::sd(z$value,na.rm=TRUE),min=min(z$value,na.rm=TRUE),max=max(z$value,na.rm=TRUE),n_folds=nrow(z),row.names=NULL);if("target"%in%names(z))base$target<-z$target[[1]];base}))
  meta<-ResultMeta(run_id=.smf_new_run_id(),created_at=.smf_now(),package_version=.smf_version(),backend=spec@model@engine,backend_version=character(),data_hash=smf_data_hash(data),split_hash=resamples@manifest_hash,spec_hash=smf_hash(spec),seed=spec@resampling@seed,warnings=list(),provenance=list(operation="resample_experiment",calibration_fold_safe=TRUE,imbalance_fold_safe=TRUE))
  ResampleResult(meta=meta,spec=spec,resamples=resamples,fold_results=fold_results,metrics=metric_rows,aggregate=agg,warnings=list())
}
