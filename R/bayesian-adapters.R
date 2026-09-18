# Optional BART and Gaussian-process adapters.

.smf_numeric_matrix <- function(x, name="x") {
  if(is.data.frame(x)) {
    bad<-names(x)[!vapply(x,is.numeric,logical(1))]
    if(length(bad)) cli::cli_abort("{.arg {name}} currently requires numeric predictors; nonnumeric columns: {paste(bad,collapse=', ')}")
    x<-as.matrix(x)
  }
  x<-as.matrix(x); storage.mode(x)<-"double"; if(any(!is.finite(x))) cli::cli_abort("{.arg {name}} contains non-finite values."); x
}

#' Fit a Bayesian additive regression tree adapter
#' @export
smf_bart_fit <- function(x, y, task=c("regression","binary"), ndpost=1000L, nskip=500L, ntree=200L, seed=260917L, ...) {
  task<-match.arg(task)
  if(!.smf_package_available("dbarts")) .smf_abort("BART_BACKEND_UNAVAILABLE","Package dbarts is required for BART.",class="smf_capability_error")
  X<-.smf_numeric_matrix(x); yy<-if(task=="binary") as.numeric(as.factor(y))-1L else as.numeric(y)
  if(length(yy)!=nrow(X)) cli::cli_abort("{.arg y} length must match rows of {.arg x}.")
  dots<-list(...); args<-c(list(x.train=X,y.train=yy,ndpost=as.integer(ndpost),nskip=as.integer(nskip),ntree=as.integer(ntree),verbose=FALSE,keeptrees=TRUE),dots)
  obj<-smf_with_seed(seed,do.call(dbarts::bart,args))
  BARTFitResult(backend="dbarts",fit=obj,task=task,predictors=colnames(X) %||% paste0("x",seq_len(ncol(X))),approximation="mcmc_bart",
    provenance=list(seed=seed,ndpost=ndpost,nskip=nskip,ntree=ntree,posterior_sampling=TRUE))
}

#' Predict from a BART fit as a posterior-sample distribution
#' @export
smf_bart_predict <- function(fit, new_data) {
  if(!S7::S7_inherits(fit,BARTFitResult)) cli::cli_abort("{.arg fit} must be a BARTFitResult.")
  X<-.smf_numeric_matrix(new_data,"new_data")
  pr<-tryCatch(stats::predict(fit@fit,newdata=X),error=function(e) tryCatch(stats::predict(fit@fit,X),error=function(e2) NULL))
  if(is.null(pr)) .smf_abort("BART_PREDICTION_FAILED","The installed dbarts backend did not expose a compatible posterior prediction method.",evidence=list(adapter="dbarts"),class="smf_capability_error")
  s<-as.matrix(pr); if(nrow(s)!=nrow(X) && ncol(s)==nrow(X)) s<-t(s)
  if(fit@task=="binary") s<-stats::pnorm(s)
  smf_prediction_distribution("samples",list(samples=s),UncertaintyDescriptor(source="bayesian_bart",target=if(fit@task=="binary")"class_probability" else "future_response",interval_type="posterior",level=0.95,conditional_on="BART prior and posterior sampler"),list(mean=TRUE,variance=TRUE,quantile=TRUE,sample=TRUE))
}

.smf_sqdist <- function(A,B) {
  aa<-rowSums(A*A); bb<-rowSums(B*B); pmax(outer(aa,bb,"+")-2*tcrossprod(A,B),0)
}
.smf_rbf_kernel <- function(A,B,length_scale,signal_variance) signal_variance*exp(-0.5*.smf_sqdist(A,B)/(length_scale^2))

.smf_gp_native_fit <- function(X,y,length_scale,signal_variance,noise_variance,optimize,jitter) {
  n<-nrow(X)
  nll<-function(theta) {
    ls<-exp(theta[1]); nv<-exp(theta[2]); K<-.smf_rbf_kernel(X,X,ls,signal_variance)+diag(nv+jitter,n); R<-tryCatch(chol(K),error=function(e) NULL); if(is.null(R)) return(Inf)
    alpha<-backsolve(R,forwardsolve(t(R),y)); 0.5*sum(y*alpha)+sum(log(diag(R)))+0.5*n*log(2*pi)
  }
  if(optimize) { op<-stats::optim(log(c(length_scale,noise_variance)),nll,method="L-BFGS-B",lower=log(c(1e-4,1e-8)),upper=log(c(1e4,1e4))); length_scale<-exp(op$par[1]); noise_variance<-exp(op$par[2]) }
  K<-.smf_rbf_kernel(X,X,length_scale,signal_variance)+diag(noise_variance+jitter,n); R<-chol(K); alpha<-backsolve(R,forwardsolve(t(R),y))
  list(X=X,y=y,R=R,alpha=alpha,jitter=jitter,optimized=optimize,length_scale=length_scale,noise_variance=noise_variance)
}

#' Fit Gaussian-process regression
#' @export
smf_gp_fit <- function(x, y, backend=c("native","DiceKriging"), length_scale=1, signal_variance=NULL, noise_variance=0.1, optimize=FALSE, standardize=TRUE, jitter=1e-8, ...) {
  backend<-match.arg(backend); X<-.smf_numeric_matrix(x); yy<-as.numeric(y); if(length(yy)!=nrow(X)) cli::cli_abort("{.arg y} length must match rows of {.arg x}.")
  center<-if(standardize) colMeans(X) else rep(0,ncol(X)); scale<-if(standardize) apply(X,2L,stats::sd) else rep(1,ncol(X)); scale[!is.finite(scale)|scale==0]<-1; Z<-sweep(sweep(X,2L,center,"-"),2L,scale,"/")
  if(is.null(signal_variance)) signal_variance<-max(stats::var(yy),1e-8)
  if(backend=="DiceKriging") {
    if(!.smf_package_available("DiceKriging")) .smf_abort("GP_BACKEND_UNAVAILABLE","Package DiceKriging is required for this GP adapter.",class="smf_capability_error")
    obj<-DiceKriging::km(design=as.data.frame(Z),response=yy,covtype="gauss",...)
    return(GPFitResult(backend="DiceKriging",fit=obj,predictors=colnames(X)%||%paste0("x",seq_len(ncol(X))),x_center=center,x_scale=scale,length_scale=as.numeric(length_scale),signal_variance=as.numeric(signal_variance),noise_variance=as.numeric(noise_variance),approximation="backend_estimated_hyperparameters",provenance=list(standardized=standardize)))
  }
  obj<-.smf_gp_native_fit(Z,yy,.smf_scalar_num(length_scale,"length_scale",0,Inf,TRUE,FALSE),.smf_scalar_num(signal_variance,"signal_variance",0,Inf,TRUE,FALSE),.smf_scalar_num(noise_variance,"noise_variance",0,Inf,FALSE,FALSE),isTRUE(optimize),jitter)
  GPFitResult(backend="native",fit=obj,predictors=colnames(X)%||%paste0("x",seq_len(ncol(X))),x_center=center,x_scale=scale,length_scale=obj$length_scale,signal_variance=signal_variance,noise_variance=obj$noise_variance,approximation=if(optimize)"exact_gp_conditional_with_mle_plugin_hyperparameters" else "exact_gp_conditional_given_fixed_hyperparameters",provenance=list(standardized=standardize,optimize=optimize,optimized_length_scale=obj$length_scale,optimized_noise_variance=obj$noise_variance))
}

#' Predict from Gaussian-process regression
#' @export
smf_gp_predict <- function(fit, new_data, include_noise=TRUE, level=0.95) {
  if(!S7::S7_inherits(fit,GPFitResult)) cli::cli_abort("{.arg fit} must be a GPFitResult.")
  Xn<-.smf_numeric_matrix(new_data,"new_data"); Z<-sweep(sweep(Xn,2L,fit@x_center,"-"),2L,fit@x_scale,"/")
  if(fit@backend=="DiceKriging") {
    pr<-stats::predict(fit@fit,newdata=as.data.frame(Z),type="UK",se.compute=TRUE,cov.compute=FALSE); mu<-as.numeric(pr$mean); sd<-as.numeric(pr$sd)
    return(smf_prediction_distribution("parametric",list(distribution="normal",mean=mu,sd=sd,components=list(total=sd^2)),UncertaintyDescriptor(source="bayesian_gp",target="future_response",interval_type="posterior_predictive",level=level,conditional_on=fit@approximation),list(mean=TRUE,variance=TRUE,quantile=TRUE,cdf=TRUE,sample=TRUE)))
  }
  obj<-fit@fit; ls<-obj$length_scale %||% fit@length_scale; nv<-obj$noise_variance %||% fit@noise_variance
  Ks<-.smf_rbf_kernel(obj$X,Z,ls,fit@signal_variance); mu<-as.numeric(crossprod(Ks,obj$alpha)); v<-forwardsolve(t(obj$R),Ks); latent<-pmax(fit@signal_variance-colSums(v*v),0); total<-latent + if(isTRUE(include_noise)) nv else 0; sd<-sqrt(pmax(total,0))
  desc<-UncertaintyDescriptor(source="bayesian_gp",target=if(include_noise)"future_response" else "latent_function",interval_type=if(include_noise)"posterior_predictive" else "credible",level=level,conditional_on=fit@approximation)
  smf_prediction_distribution("parametric",list(distribution="normal",mean=mu,sd=sd,components=list(epistemic=latent,aleatoric=rep(nv,length(latent)),total=total),identified=TRUE),desc,list(mean=TRUE,variance=TRUE,quantile=TRUE,cdf=TRUE,sample=TRUE))
}
