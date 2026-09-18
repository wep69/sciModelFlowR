.smf_class_counts <- function(y) as.list(table(y,useNA="ifany"))

#' Apply class imbalance handling to analysis/training data only
#' @export
smf_apply_imbalance <- function(data,outcome,spec=smf_imbalance_spec(),context=c("analysis","training","assessment","test"),seed=260915L) {
  context<-match.arg(context)
  if(context %in% c("assessment","test")) .smf_abort("IMBALANCE_LEAKAGE","Sampling or class-weight estimation must not be learned/applied from assessment or final test labels.",class="smf_leakage_error")
  .smf_abort_missing_columns(data,outcome,"imbalance handling"); y<-as.factor(data[[outcome]]); before<-.smf_class_counts(y); method<-spec@method
  if(method=="none") return(ImbalanceResult(method=method,data=data,weights=NULL,before=before,after=before,training_hash=smf_data_hash(data),provenance=list(context=context)))
  if(method=="weights") {
    cnt<-table(y); w<-length(y)/(length(cnt)*as.numeric(cnt)); names(w)<-names(cnt); ww<-unname(w[as.character(y)])
    return(ImbalanceResult(method=method,data=data,weights=ww,before=before,after=before,training_hash=smf_data_hash(data),provenance=list(context=context,formula="inverse class frequency")))
  }
  if(method %in% c("downsample","upsample")) {
    lev<-levels(y); idxs<-split(seq_len(nrow(data)),y); sizes<-lengths(idxs); target<-if(method=="downsample") min(sizes) else ceiling(max(sizes)*spec@ratio)
    sel<-smf_with_seed(seed,unlist(lapply(idxs,function(ix) sample(ix,size=target,replace=method=="upsample" || length(ix)<target)),use.names=FALSE)); out<-data[sel,,drop=FALSE]
    return(ImbalanceResult(method=method,data=out,weights=NULL,before=before,after=.smf_class_counts(as.factor(out[[outcome]])),training_hash=smf_data_hash(data),provenance=list(context=context,seed=seed,target=target)))
  }
  if(!requireNamespace("recipes",quietly=TRUE) || !requireNamespace("themis",quietly=TRUE)) .smf_abort("THEMIS_MISSING","Packages 'recipes' and 'themis' are required for SMOTE methods.",class="smf_capability_error")
  f<-stats::reformulate(setdiff(names(data),outcome),response=outcome); rec<-recipes::recipe(f,data=data)
  rec<-switch(method,
    smote=themis::step_smote(rec,recipes::all_outcomes(),over_ratio=spec@ratio,neighbors=spec@neighbors,skip=TRUE,seed=seed),
    bsmote=themis::step_bsmote(rec,recipes::all_outcomes(),over_ratio=spec@ratio,neighbors=spec@neighbors,skip=TRUE,seed=seed),
    smotenc=themis::step_smotenc(rec,recipes::all_outcomes(),over_ratio=spec@ratio,neighbors=spec@neighbors,skip=TRUE,seed=seed),
    smoten=themis::step_smoten(rec,recipes::all_outcomes(),over_ratio=spec@ratio,neighbors=spec@neighbors,skip=TRUE,seed=seed))
  prep<-recipes::prep(rec,training=data,retain=TRUE); out<-as.data.frame(recipes::juice(prep)); out[[outcome]]<-factor(out[[outcome]],levels=levels(y))
  ImbalanceResult(method=method,data=out,weights=NULL,before=before,after=.smf_class_counts(out[[outcome]]),training_hash=smf_data_hash(data),provenance=list(context=context,seed=seed,ratio=spec@ratio,neighbors=spec@neighbors))
}

.smf_threshold_metric <- function(truth,pred,metric,positive) {
  m<-.smf_confusion_metrics(truth,pred,positive)
  switch(metric,balanced_accuracy=m$balanced_accuracy,f1=m$f1,mcc=m$mcc,sensitivity=m$sensitivity,specificity=m$specificity,accuracy=m$accuracy,cli::cli_abort("Unsupported threshold metric {.val {metric}}."))
}

#' Optimize a binary probability threshold using calibration/validation data
#' @export
smf_optimize_threshold <- function(truth,probability,metric=c("balanced_accuracy","f1","mcc","sensitivity","specificity","accuracy"),grid=seq(0.05,0.95,by=0.01),positive_label=NULL) {
  metric<-match.arg(metric); truth<-as.factor(truth); if(nlevels(truth)!=2L) cli::cli_abort("Threshold optimization requires a binary outcome.")
  pos<-positive_label %||% levels(truth)[[2]]; neg<-setdiff(levels(truth),pos)[[1]]; p<-as.numeric(probability)
  scores<-vapply(grid,function(t){pred<-factor(ifelse(p>=t,pos,neg),levels=levels(truth)); .smf_threshold_metric(truth,pred,metric,pos)},numeric(1))
  j<-which.max(scores); list(threshold=grid[[j]],metric=metric,value=scores[[j]],positive_label=pos,curve=data.frame(threshold=grid,value=scores))
}
