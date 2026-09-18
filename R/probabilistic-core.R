#' Construct a package-native prediction distribution
#' @export
smf_prediction_distribution <- function(representation=c("point","class_probabilities","samples","quantiles","parametric","interval"), payload, uncertainty=NULL, capabilities=list()) {
  PredictionDistribution(representation=match.arg(representation),payload=payload,uncertainty=uncertainty,capabilities=capabilities)
}

.smf_dist_fail <- function(op,dist) .smf_abort("DISTRIBUTION_OPERATION_UNAVAILABLE",paste0("Operation '",op,"' is unavailable for representation '",dist@representation,"'."),class="smf_capability_error")

#' Distribution mean
#' @export
smf_dist_mean <- function(dist) {
  switch(dist@representation,
    point=as.numeric(dist@payload$mean),
    samples=rowMeans(as.matrix(dist@payload$samples)),
    parametric={ if(identical(dist@payload$distribution,"normal")) as.numeric(dist@payload$mean) else .smf_dist_fail("mean",dist) },
    .smf_dist_fail("mean",dist))
}

#' Distribution median
#' @export
smf_dist_median <- function(dist) {
  if(dist@representation=="samples") return(apply(as.matrix(dist@payload$samples),1L,stats::median))
  if(dist@representation=="quantiles") return(smf_dist_quantile(dist,0.5))
  if(dist@representation %in% c("point","parametric")) return(smf_dist_mean(dist))
  .smf_dist_fail("median",dist)
}

#' Distribution variance
#' @export
smf_dist_variance <- function(dist) {
  if(dist@representation=="samples") return(apply(as.matrix(dist@payload$samples),1L,stats::var))
  if(dist@representation=="parametric" && identical(dist@payload$distribution,"normal")) return(as.numeric(dist@payload$sd)^2)
  if(dist@representation=="point") return(rep(0,length(dist@payload$mean)))
  .smf_dist_fail("variance",dist)
}

#' Distribution standard deviation
#' @export
smf_dist_sd <- function(dist) sqrt(smf_dist_variance(dist))

#' Distribution quantiles
#' @export
smf_dist_quantile <- function(dist, probs) {
  probs <- as.numeric(probs); if(any(probs<0|probs>1)) cli::cli_abort("{.arg probs} must be in [0,1].")
  if(dist@representation=="samples") return(t(apply(as.matrix(dist@payload$samples),1L,stats::quantile,probs=probs,names=FALSE,type=8)))
  if(dist@representation=="point") return(matrix(rep(as.numeric(dist@payload$mean),each=length(probs)),nrow=length(dist@payload$mean),byrow=TRUE,dimnames=list(NULL,paste0("q",probs))))
  if(dist@representation=="parametric" && identical(dist@payload$distribution,"normal")) {
    mu<-as.numeric(dist@payload$mean); sd<-as.numeric(dist@payload$sd); return(sapply(probs,function(q) stats::qnorm(q,mu,sd)))
  }
  if(dist@representation=="quantiles") {
    q0<-as.numeric(dist@payload$probs); m<-as.matrix(dist@payload$quantiles)
    return(t(apply(m,1L,function(z) stats::approx(q0,z,xout=probs,rule=2,ties="ordered")$y)))
  }
  .smf_dist_fail("quantile",dist)
}

#' Central distribution interval
#' @export
smf_dist_interval <- function(dist, level=0.95) {
  a<-(1-level)/2; q<-smf_dist_quantile(dist,c(a,1-a)); colnames(q)<-c("lower","upper"); q
}

#' Sample from a prediction distribution
#' @export
smf_dist_sample <- function(dist,n=1L,seed=NULL) {
  n<-as.integer(n)
  f<-function(){
    if(dist@representation=="parametric" && identical(dist@payload$distribution,"normal")) return(sapply(seq_len(n),function(i) stats::rnorm(length(dist@payload$mean),dist@payload$mean,dist@payload$sd)))
    if(dist@representation=="samples") { s<-as.matrix(dist@payload$samples); idx<-sample.int(ncol(s),n,replace=TRUE); return(s[,idx,drop=FALSE]) }
    .smf_dist_fail("sample",dist)
  }
  if(is.null(seed)) f() else smf_with_seed(seed,f())
}

#' Log probability or log density
#' @export
smf_dist_log_prob <- function(dist,value) {
  if(dist@representation=="parametric" && identical(dist@payload$distribution,"normal")) return(stats::dnorm(as.numeric(value),dist@payload$mean,dist@payload$sd,log=TRUE))
  if(dist@representation=="class_probabilities") {
    p<-as.matrix(dist@payload$prob); truth<-as.character(value); idx<-match(truth,colnames(p)); if(anyNA(idx)) cli::cli_abort("Truth contains labels absent from probability columns.")
    return(log(.smf_clip_prob(p[cbind(seq_len(nrow(p)),idx)])))
  }
  .smf_dist_fail("log_prob",dist)
}

#' CDF from a parametric prediction distribution
#' @export
smf_dist_cdf <- function(dist,value) {
  if(dist@representation=="parametric" && identical(dist@payload$distribution,"normal")) return(stats::pnorm(as.numeric(value),dist@payload$mean,dist@payload$sd))
  .smf_dist_fail("cdf",dist)
}

#' Convert model predictions to the stable PredictionDistribution contract
#' @export
smf_predict_distribution <- function(result,new_data=NULL) {
  if (S7::S7_inherits(result,ExperimentResult)) {
    if(is.null(new_data) && !is.null(result@prediction@distribution)) return(result@prediction@distribution)
    if(is.null(new_data)) cli::cli_abort("Supply {.arg new_data} or use an ExperimentResult that already contains a distribution.")
    fit<-result@fit; task<-result@spec@task
  } else if(S7::S7_inherits(result,FitResult)) {
    if(is.null(new_data)) cli::cli_abort("{.arg new_data} is required for a FitResult.")
    fit<-result; task<-smf_task_spec(if(length(fit@training_summary$class_levels)>2L)"multiclass" else fit@training_summary$task_kind,target=fit@target)
  } else cli::cli_abort("{.arg result} must be an ExperimentResult or FitResult.")
  pred<-smf_predict(result,new_data)
  if(task@kind %in% c("binary","multiclass")) return(smf_prediction_distribution("class_probabilities",list(prob=as.matrix(pred),classes=colnames(as.matrix(pred))),uncertainty=UncertaintyDescriptor(source="analytical",target="class_probability",interval_type="none",level=NA_real_,conditional_on="fitted model"),capabilities=list(log_prob=TRUE,calibration=TRUE)))
  smf_prediction_distribution("point",list(mean=as.numeric(pred)),uncertainty=UncertaintyDescriptor(source="analytical",target="prediction",interval_type="none",level=NA_real_,conditional_on="fitted model"),capabilities=list(mean=TRUE))
}
