.smf_cal_truth_factor <- function(truth,prob) factor(truth,levels=colnames(prob))

#' Estimate a calibration model without using final test labels
#' @export
smf_calibrate <- function(truth,probabilities,spec=smf_calibration_spec("platt"),training_data=NULL) {
  if(!S7::S7_inherits(spec,CalibrationSpec)) cli::cli_abort("{.arg spec} must be a CalibrationSpec.")
  prob<-as.matrix(probabilities); .smf_validate_prob_matrix(prob,truth)
  truth<-.smf_cal_truth_factor(truth,prob); method<-spec@method
  if(method=="none") model<-NULL
  else if(method=="platt") {
    if(ncol(prob)!=2L) .smf_abort("PLATT_BINARY_ONLY","Platt calibration in 0.3.0 is restricted to binary classification; use multinomial or isotonic for multiclass.",class="smf_calibration_error")
    pos<-levels(truth)[[2]]; score<-stats::qlogis(.smf_clip_prob(prob[,pos])); y<-as.integer(truth==pos)
    model<-stats::glm(y~score,family=stats::binomial())
  } else if(method=="isotonic") {
    model<-lapply(colnames(prob),function(cl){z<-stats::isoreg(prob[,cl],as.integer(truth==cl)); o<-order(z$x); list(x=z$x[o],yf=z$yf[o])}); names(model)<-colnames(prob)
  } else if(method=="multinomial") {
    if(!requireNamespace("nnet",quietly=TRUE)) .smf_abort("NNET_MISSING","Package 'nnet' is required for multinomial calibration.",class="smf_capability_error")
    ref<-colnames(prob)[ncol(prob)]; zz<-log(.smf_clip_prob(prob[,seq_len(ncol(prob)-1),drop=FALSE])/ .smf_clip_prob(prob[,ref])); colnames(zz)<-paste0("lp_",seq_len(ncol(zz))); d<-data.frame(.truth=truth,zz,check.names=FALSE)
    model<-nnet::multinom(.truth~.,data=d,trace=FALSE)
  } else if(method=="beta") {
    .smf_abort("BETA_CALIBRATION_ADAPTER_ONLY","Beta calibration is declared but requires the optional probably/betacal adapter and is not selected automatically in 0.3.0.",class="smf_capability_error")
  }
  diag<-smf_calibration_report(truth,prob,bins=spec@bins)
  CalibrationResult(method=method,source=spec@source,model=model,class_levels=colnames(prob),positive_label=if(ncol(prob)==2L)colnames(prob)[[2]] else NULL,training_hash=if(is.null(training_data)) smf_hash(list(truth=as.character(truth),prob=prob)) else smf_data_hash(training_data),n=as.integer(length(truth)),diagnostics=diag,warnings=list())
}

#' Apply an estimated calibration model
#' @export
smf_apply_calibration <- function(calibration,probabilities) {
  if(!S7::S7_inherits(calibration,CalibrationResult)) cli::cli_abort("{.arg calibration} must be a CalibrationResult.")
  p<-as.matrix(probabilities); colnames(p)<-colnames(p) %||% calibration@class_levels
  if(!identical(colnames(p),calibration@class_levels)) p<-p[,calibration@class_levels,drop=FALSE]
  if(calibration@method=="none") return(p)
  if(calibration@method=="platt") {
    pos<-calibration@positive_label; score<-stats::qlogis(.smf_clip_prob(p[,pos])); q<-as.numeric(stats::predict(calibration@model,newdata=data.frame(score=score),type="response")); out<-cbind(1-q,q); colnames(out)<-calibration@class_levels; return(out)
  }
  if(calibration@method=="isotonic") {
    out<-sapply(calibration@class_levels,function(cl){m<-calibration@model[[cl]]; stats::approx(m$x,m$yf,xout=p[,cl],rule=2,ties="ordered")$y}); out<-as.matrix(out); out[out<0]<-0; out[out>1]<-1; rs<-rowSums(out); rs[rs==0]<-1; out<-out/rs; colnames(out)<-calibration@class_levels; return(out)
  }
  if(calibration@method=="multinomial") {
    ref<-calibration@class_levels[length(calibration@class_levels)]; zz<-log(.smf_clip_prob(p[,seq_len(ncol(p)-1),drop=FALSE])/.smf_clip_prob(p[,ref])); colnames(zz)<-paste0("lp_",seq_len(ncol(zz))); out<-as.matrix(stats::predict(calibration@model,newdata=data.frame(zz,check.names=FALSE),type="probs")); if(is.vector(out)) out<-cbind(1-out,out); colnames(out)<-calibration@class_levels; return(out)
  }
  .smf_abort("CALIBRATION_APPLY_UNSUPPORTED","Calibration method cannot be applied.",class="smf_capability_error")
}
