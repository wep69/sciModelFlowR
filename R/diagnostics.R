smf_diagnose_fit <- function(fit,prediction) {
  y<-prediction@truth; p<-prediction@estimate
  is_prob<-!is.null(prediction@probabilities)
  if(is_prob) {
    prob<-as.matrix(prediction@probabilities); checks<-list(n=nrow(prob),finite_predictions=all(is.finite(prob)),missing_predictions=sum(is.na(prob)),probability_rows_sum_to_one=max(abs(rowSums(prob)-1))<1e-8)
    evidence<-smf_calibration_report(y,prob)
    return(DiagnosticResult(meta=fit@meta,checks=checks,residuals=NULL,fitted=prob,evidence=evidence,warnings=list()))
  }
  if(is.data.frame(y) || is.matrix(y)) {
    yy<-as.matrix(y); pp<-as.matrix(p); res<-yy-pp
    checks<-list(n=nrow(pp),targets=ncol(pp),finite_predictions=all(is.finite(pp)),missing_predictions=sum(is.na(pp)))
    evidence<-list(rmse_by_target=sqrt(colMeans(res^2,na.rm=TRUE)))
    return(DiagnosticResult(meta=fit@meta,checks=checks,residuals=res,fitted=pp,evidence=evidence,warnings=list()))
  }
  residuals<-if(is.numeric(y)) as.numeric(y)-as.numeric(p) else NULL
  checks<-list(n=length(p),finite_predictions=all(is.finite(p)),missing_predictions=sum(is.na(p)))
  evidence<-list(rmse=if(is.numeric(y)) sqrt(mean((as.numeric(y)-as.numeric(p))^2,na.rm=TRUE)) else NA_real_)
  DiagnosticResult(meta=fit@meta,checks=checks,residuals=residuals,fitted=p,evidence=evidence,warnings=list())
}

#' Diagnose an experiment or fit result
#' @export
smf_diagnose <- function(result) {
  if(S7::S7_inherits(result,ExperimentResult)) return(result@diagnostics)
  cli::cli_abort("{.fn smf_diagnose} expects an ExperimentResult in version 0.5.0.")
}

#' Create a scientific diagnostic plot
#' @export
smf_plot <- function(result,type=c("observed_predicted","residuals","calibration")) {
  type<-match.arg(type)
  if(!S7::S7_inherits(result,ExperimentResult)) cli::cli_abort("{.arg result} must be an ExperimentResult.")
  if(!requireNamespace("ggplot2",quietly=TRUE)) cli::cli_abort("Package {.pkg ggplot2} is required for plotting.")
  y<-result@prediction@truth
  if(type=="calibration") {
    prob<-result@prediction@probabilities
    if(is.null(prob)) cli::cli_abort("Calibration plots require class probabilities.")
    tab<-smf_calibration_report(y,prob)$table
    return(ggplot2::ggplot(tab,ggplot2::aes(x=mean_probability,y=observed_frequency,size=n))+ggplot2::geom_point()+ggplot2::geom_abline(slope=1,intercept=0,linetype=2)+ggplot2::facet_wrap(~class)+ggplot2::labs(x="Mean predicted probability",y="Observed frequency",title="Probability calibration"))
  }
  p<-result@prediction@estimate
  if(!is.numeric(y) || !is.numeric(p)) cli::cli_abort("Observed-predicted and residual plots currently require a scalar numeric response.")
  df<-data.frame(observed=as.numeric(y),predicted=as.numeric(p),residual=as.numeric(y)-as.numeric(p))
  if(type=="observed_predicted") ggplot2::ggplot(df,ggplot2::aes(x=observed,y=predicted))+ggplot2::geom_point()+ggplot2::geom_abline(slope=1,intercept=0,linetype=2)+ggplot2::labs(x="Observed",y="Predicted",title="Observed versus predicted")
  else ggplot2::ggplot(df,ggplot2::aes(x=predicted,y=residual))+ggplot2::geom_point()+ggplot2::geom_hline(yintercept=0,linetype=2)+ggplot2::labs(x="Fitted",y="Residual",title="Residual diagnostic")
}
