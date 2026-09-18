# Metric layer for deterministic and probability-aware supervised prediction.

.smf_regression_metric <- function(name, y, p) {
  switch(name,
    rmse=sqrt(mean((y-p)^2)),
    mae=mean(abs(y-p)),
    mse=mean((y-p)^2),
    rsq={ den<-sum((y-mean(y))^2); if(den>0) 1-sum((y-p)^2)/den else NA_real_ },
    r_squared={ den<-sum((y-mean(y))^2); if(den>0) 1-sum((y-p)^2)/den else NA_real_ },
    cli::cli_abort("Regression metric {.val {name}} is not implemented."))
}

.smf_class_metric <- function(name, truth, prob, positive_label=NULL, threshold=0.5) {
  prob<-as.matrix(prob); .smf_validate_prob_matrix(prob,truth)
  truth<-factor(truth,levels=colnames(prob)); pred<-.smf_classification_from_prob(prob,threshold,positive_label)
  cm<-.smf_confusion_metrics(truth,pred,positive_label)
  if(name %in% names(cm)) return(cm[[name]])
  if(name=="log_loss") return(-mean(log(.smf_clip_prob(prob[cbind(seq_len(nrow(prob)),match(as.character(truth),colnames(prob)))]))))
  if(name=="brier") {
    yy<-sapply(colnames(prob),function(cl)as.numeric(truth==cl)); if(is.vector(yy)) yy<-matrix(yy,ncol=ncol(prob)); return(mean(rowSums((yy-prob)^2)))
  }
  if(name %in% c("roc_auc","pr_auc")) {
    if(ncol(prob)==2L) {
      pos<-positive_label %||% colnames(prob)[[2]]; y<-as.integer(truth==pos); p<-prob[,pos]
      return(if(name=="roc_auc") .smf_binary_auc(y,p) else .smf_binary_pr_auc(y,p))
    }
    vals<-vapply(colnames(prob),function(cl){y<-as.integer(truth==cl); p<-prob[,cl]; if(name=="roc_auc") .smf_binary_auc(y,p) else .smf_binary_pr_auc(y,p)},numeric(1))
    return(mean(vals,na.rm=TRUE))
  }
  if(name=="ece") return(smf_calibration_report(truth,prob)$ece)
  cli::cli_abort("Classification metric {.val {name}} is not implemented.")
}

#' Evaluate deterministic or probability-based supervised metrics
#' @export
smf_evaluate <- function(truth, estimate, metrics=list(smf_metric_spec("rmse")), positive_label=NULL, threshold=0.5) {
  if(!is.list(metrics)) metrics<-list(metrics)
  # Multi-output numeric regression: columns are evaluated separately.
  if(is.data.frame(truth) || (is.matrix(truth) && ncol(truth)>1L)) {
    y<-as.data.frame(truth); p<-as.data.frame(estimate)
    if(nrow(y)!=nrow(p) || ncol(y)!=ncol(p)) cli::cli_abort("Multi-output truth and estimate dimensions must match.")
    if(is.null(names(p)) || any(!nzchar(names(p)))) names(p)<-names(y)
    rows<-list()
    for(j in seq_len(ncol(y))) for(m in metrics) {
      nm<-tolower(m@name); ok<-stats::complete.cases(y[[j]],p[[j]])
      rows[[length(rows)+1L]]<-data.frame(metric=m@name,target=names(y)[[j]],value=.smf_regression_metric(nm,as.numeric(y[[j]][ok]),as.numeric(p[[j]][ok])),direction=m@direction,n=sum(ok),row.names=NULL)
    }
    return(do.call(rbind,rows))
  }
  # Probability matrices are interpreted as classification predictions.
  if(is.matrix(estimate) || (is.data.frame(estimate) && ncol(estimate)>1L && !is.numeric(truth))) {
    prob<-as.matrix(estimate); if(length(truth)!=nrow(prob)) cli::cli_abort("Truth length and probability rows must match.")
    rows<-lapply(metrics,function(m){nm<-tolower(m@name); data.frame(metric=m@name,value=.smf_class_metric(nm,truth,prob,positive_label,threshold),direction=m@direction,n=length(truth),row.names=NULL)})
    return(do.call(rbind,rows))
  }
  # Numeric deterministic regression and legacy probability vector support.
  if(length(truth)!=length(estimate)) cli::cli_abort("Truth and estimate lengths must match.")
  rows<-lapply(metrics,function(m){
    nm<-tolower(m@name); ok<-stats::complete.cases(truth,estimate); y<-truth[ok]; p<-estimate[ok]
    value<-if(is.numeric(y)) .smf_regression_metric(nm,as.numeric(y),as.numeric(p)) else {
      if(nm=="accuracy") mean(y==p) else cli::cli_abort("Hard-label metric {.val {m@name}} is not implemented for this input form.")
    }
    data.frame(metric=m@name,value=value,direction=m@direction,n=length(y),row.names=NULL)
  })
  do.call(rbind,rows)
}
