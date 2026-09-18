.smf_validate_prob_matrix <- function(prob,truth=NULL,tol=1e-8) {
  prob<-as.matrix(prob)
  if(!is.numeric(prob) || !nrow(prob) || !ncol(prob)) .smf_abort("PROBABILITY_MATRIX_INVALID","Probabilities must be a non-empty numeric matrix.",class="smf_validation_error")
  if(any(!is.finite(prob)) || any(prob < -tol) || any(prob > 1+tol)) .smf_abort("PROBABILITY_RANGE","Class probabilities must lie in [0,1].",class="smf_validation_error")
  rs<-rowSums(prob); if(any(abs(rs-1)>tol)) .smf_abort("PROBABILITY_SUM","Class-probability rows must sum to one within tolerance.",evidence=list(max_deviation=max(abs(rs-1))),class="smf_validation_error")
  if(!is.null(truth) && (is.null(colnames(prob)) || any(!as.character(truth) %in% colnames(prob)))) .smf_abort("PROBABILITY_LABELS","Probability columns must be named for all observed classes.",class="smf_validation_error")
  invisible(TRUE)
}

.smf_classification_from_prob <- function(prob,threshold=0.5,positive=NULL) {
  prob<-as.matrix(prob); lv<-colnames(prob)
  if(ncol(prob)==2L) {
    pos<-positive %||% lv[[2]]; j<-match(pos,lv); neg<-lv[setdiff(seq_along(lv),j)][[1]]
    factor(ifelse(prob[,j]>=threshold,pos,neg),levels=lv)
  } else factor(lv[max.col(prob,ties.method="first")],levels=lv)
}

.smf_binary_auc <- function(y,p) {
  y<-as.integer(y); n1<-sum(y==1); n0<-sum(y==0); if(!n1||!n0) return(NA_real_)
  r<-rank(p,ties.method="average"); (sum(r[y==1])-n1*(n1+1)/2)/(n1*n0)
}

.smf_binary_pr_auc <- function(y,p) {
  ord<-order(p,decreasing=TRUE); y<-as.integer(y[ord]); tp<-cumsum(y==1); fp<-cumsum(y==0); rec<-tp/max(1,sum(y==1)); prec<-tp/pmax(tp+fp,1)
  rec0<-c(0,rec); prec0<-c(1,prec); sum(diff(rec0)*(head(prec0,-1)+tail(prec0,-1))/2)
}

.smf_confusion_metrics <- function(truth,pred,positive=NULL) {
  truth<-as.factor(truth); pred<-factor(pred,levels=levels(truth)); tab<-table(pred,truth); k<-nlevels(truth)
  acc<-sum(diag(tab))/sum(tab)
  recall<-diag(tab)/pmax(colSums(tab),1); precision<-diag(tab)/pmax(rowSums(tab),1)
  bal<-mean(recall,na.rm=TRUE); f1<-mean(2*precision*recall/pmax(precision+recall,.Machine$double.eps),na.rm=TRUE)
  pe<-sum(rowSums(tab)*colSums(tab))/sum(tab)^2; kappa<-(acc-pe)/(1-pe)
  out<-list(accuracy=acc,balanced_accuracy=bal,precision=mean(precision,na.rm=TRUE),recall=mean(recall,na.rm=TRUE),f1=f1,kappa=kappa)
  if(k==2L) {
    pos<-positive %||% levels(truth)[[2]]; j<-match(pos,levels(truth)); neg<-setdiff(seq_len(2),j)
    tp<-tab[j,j]; fn<-sum(tab[,j])-tp; fp<-sum(tab[j,])-tp; tn<-tab[neg,neg]
    out$sensitivity<-tp/max(tp+fn,1); out$specificity<-tn/max(tn+fp,1)
    den<-sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn)); out$mcc<-if(den>0)(tp*tn-fp*fn)/den else NA_real_
  }
  out
}

#' Calibration table and expected calibration error
#' @export
smf_calibration_report <- function(truth,probabilities,bins=10L,positive_label=NULL) {
  prob<-as.matrix(probabilities); .smf_validate_prob_matrix(prob,truth)
  truth<-factor(truth,levels=colnames(prob)); bins<-as.integer(bins)
  one_class<-function(cls) {
    p<-prob[,cls]; y<-as.integer(truth==cls); cuts<-cut(p,breaks=seq(0,1,length.out=bins+1),include.lowest=TRUE,labels=FALSE)
    tab<-do.call(rbind,lapply(seq_len(bins),function(b){i<-which(cuts==b); if(!length(i))return(NULL); data.frame(class=cls,bin=b,n=length(i),mean_probability=mean(p[i]),observed_frequency=mean(y[i]),abs_gap=abs(mean(p[i])-mean(y[i])))}))
    if(is.null(tab)) return(data.frame()); tab
  }
  table<-do.call(rbind,lapply(colnames(prob),one_class)); ece<-if(nrow(table)) weighted.mean(table$abs_gap,table$n) else NA_real_
  idx<-match(as.character(truth),colnames(prob)); ll<--mean(log(.smf_clip_prob(prob[cbind(seq_len(nrow(prob)),idx)])))
  yy<-sapply(colnames(prob),function(cl)as.numeric(truth==cl)); if(is.vector(yy))yy<-matrix(yy,ncol=ncol(prob)); brier<-mean(rowSums((yy-prob)^2))
  list(table=table,ece=ece,log_loss=ll,brier=brier,bins=bins,positive_label=positive_label)
}

#' Evaluate probabilistic predictions
#' @export
smf_evaluate_probabilistic <- function(truth,distribution,metrics=c("log_loss","brier","ece"),level=0.95) {
  if(!S7::S7_inherits(distribution,PredictionDistribution)) cli::cli_abort("{.arg distribution} must be a PredictionDistribution.")
  out<-list()
  for(nm in tolower(metrics)) {
    val<-switch(nm,
      log_loss={ if(distribution@representation!="class_probabilities") .smf_dist_fail(nm,distribution); -mean(smf_dist_log_prob(distribution,truth)) },
      nll={ -mean(smf_dist_log_prob(distribution,truth)) },
      brier={ if(distribution@representation!="class_probabilities") .smf_dist_fail(nm,distribution); smf_calibration_report(truth,distribution@payload$prob)$brier },
      ece={ if(distribution@representation!="class_probabilities") .smf_dist_fail(nm,distribution); smf_calibration_report(truth,distribution@payload$prob)$ece },
      crps={
        if(distribution@representation=="parametric" && identical(distribution@payload$distribution,"normal")) {
          y<-as.numeric(truth); mu<-distribution@payload$mean; sd<-distribution@payload$sd; z<-(y-mu)/sd; mean(sd*(z*(2*stats::pnorm(z)-1)+2*stats::dnorm(z)-1/sqrt(pi)))
        } else .smf_dist_fail(nm,distribution)
      },
      coverage={ q<-smf_dist_interval(distribution,level); mean(as.numeric(truth)>=q[,1]&as.numeric(truth)<=q[,2]) },
      interval_width={ q<-smf_dist_interval(distribution,level); mean(q[,2]-q[,1]) },
      interval_score={ q<-smf_dist_interval(distribution,level); y<-as.numeric(truth); a<-1-level; mean((q[,2]-q[,1])+(2/a)*(q[,1]-y)*(y<q[,1])+(2/a)*(y-q[,2])*(y>q[,2])) },
      cli::cli_abort("Unknown probabilistic metric {.val {nm}}."))
    out[[length(out)+1L]]<-data.frame(metric=nm,value=as.numeric(val),direction=if(nm %in% c("coverage"))"none" else "minimize",n=length(truth),row.names=NULL)
  }
  do.call(rbind,out)
}
