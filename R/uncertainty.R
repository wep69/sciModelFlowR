# Typed uncertainty semantics shared across modeling paradigms.

UncertaintyDecomposition <- S7::new_class(
  "UncertaintyDecomposition",
  properties = list(aleatoric=S7::class_any, epistemic=S7::class_any,
    total=S7::class_any, identified=S7::class_logical,
    method=S7::class_character, provenance=S7::class_any)
)

#' Create a typed uncertainty descriptor
#' @export
smf_uncertainty_descriptor <- function(source, target, interval_type, level=0.95, conditional_on=character()) {
  UncertaintyDescriptor(source=.smf_scalar_chr(source,"source"),target=.smf_scalar_chr(target,"target"),interval_type=.smf_scalar_chr(interval_type,"interval_type"),level=as.numeric(level),conditional_on=.smf_chr(conditional_on))
}

#' Return the package uncertainty-semantics registry
#' @export
smf_uncertainty_semantics <- function() {
  data.frame(
    interval_type=c("confidence","credible","prediction","posterior_predictive","bootstrap","conformal"),
    target=c("parameter or estimand","parameter/latent quantity","future response","future response","estimator/statistic","future response or class set"),
    probability_statement=c("repeated-sample procedure","posterior probability conditional on model/prior","sampling distribution conditional on fitted model","posterior predictive probability","resampling approximation","marginal coverage under conformal assumptions"),
    interchangeable=FALSE,
    stringsAsFactors=FALSE
  )
}

#' Label an uncertainty descriptor without erasing its semantics
#' @export
smf_uncertainty_label <- function(descriptor) {
  if(!S7::S7_inherits(descriptor,UncertaintyDescriptor)) cli::cli_abort("{.arg descriptor} must be an UncertaintyDescriptor.")
  paste0(descriptor@interval_type," ",format(100*descriptor@level,trim=TRUE),"% [",descriptor@source,"; target=",descriptor@target,"]")
}

#' Compare typed uncertainty descriptors
#' @export
smf_uncertainty_compare <- function(...) {
  xs<-list(...); if(!length(xs)) return(data.frame())
  do.call(rbind,lapply(seq_along(xs),function(i){ x<-xs[[i]]; if(S7::S7_inherits(x,PredictionDistribution)) x<-x@uncertainty; if(!S7::S7_inherits(x,UncertaintyDescriptor)) cli::cli_abort("All inputs must be UncertaintyDescriptor or PredictionDistribution objects."); data.frame(id=i,source=x@source,target=x@target,interval_type=x@interval_type,level=x@level,conditional_on=paste(x@conditional_on,collapse="; "),label=smf_uncertainty_label(x),stringsAsFactors=FALSE) }))
}

#' Validate uncertainty semantics
#' @export
smf_uncertainty_validate <- function(descriptor) {
  if(!S7::S7_inherits(descriptor,UncertaintyDescriptor)) cli::cli_abort("{.arg descriptor} must be an UncertaintyDescriptor.")
  known<-smf_uncertainty_semantics()$interval_type
  warnings<-list()
  if(!descriptor@interval_type %in% known) warnings[[length(warnings)+1L]]<-smf_warning_record("UNCERTAINTY_INTERVAL_TYPE_NONSTANDARD","The interval type is not one of the package canonical semantic categories.","warning",evidence=list(interval_type=descriptor@interval_type))
  if(identical(descriptor@interval_type,"conformal") && !grepl("future",descriptor@target,fixed=TRUE) && !grepl("class",descriptor@target,fixed=TRUE)) warnings[[length(warnings)+1L]]<-smf_warning_record("CONFORMAL_TARGET_MISMATCH","Conformal intervals/sets should target future outcomes or class membership rather than model parameters.","high",evidence=list(target=descriptor@target))
  list(valid=!any(vapply(warnings,function(w) w@severity %in% c("high","blocking"),logical(1))),warnings=warnings,descriptor=descriptor)
}

#' Decompose uncertainty only when components are scientifically identifiable
#' @export
smf_uncertainty_decompose <- function(aleatoric, epistemic, total=NULL, method, identified=FALSE, provenance=list(), tolerance=1e-8) {
  if(!isTRUE(identified)) .smf_abort("UNCERTAINTY_NOT_IDENTIFIABLE","Aleatoric/epistemic decomposition was requested without an identified decomposition contract.",evidence=list(method=method),class="smf_validation_error")
  a<-as.numeric(aleatoric); e<-as.numeric(epistemic); if(length(a)!=length(e) && length(a)!=1L && length(e)!=1L) cli::cli_abort("Aleatoric and epistemic components must be conformable.")
  calc<-a+e
  if(is.null(total)) total<-calc else { total<-as.numeric(total); if(length(total)!=length(calc) && length(total)!=1L) cli::cli_abort("{.arg total} is not conformable with uncertainty components."); if(any(abs(total-calc)>tolerance*(1+abs(total)),na.rm=TRUE)) .smf_abort("UNCERTAINTY_DECOMPOSITION_INCONSISTENT","Total uncertainty is inconsistent with aleatoric + epistemic components.",evidence=list(tolerance=tolerance),class="smf_validation_error") }
  UncertaintyDecomposition(aleatoric=a,epistemic=e,total=as.numeric(total),identified=TRUE,method=.smf_scalar_chr(method,"method"),provenance=provenance)
}

#' Extract a typed decomposition from compatible prediction distributions
#' @export
smf_uncertainty_from_distribution <- function(distribution) {
  if(!S7::S7_inherits(distribution,PredictionDistribution)) cli::cli_abort("{.arg distribution} must be a PredictionDistribution.")
  comp<-distribution@payload$components
  if(is.null(comp) || !isTRUE(distribution@payload$identified)) .smf_abort("UNCERTAINTY_NOT_IDENTIFIABLE","This prediction distribution does not expose an identified aleatoric/epistemic decomposition.",class="smf_validation_error")
  smf_uncertainty_decompose(comp$aleatoric,comp$epistemic,comp$total,method=distribution@uncertainty@source,identified=TRUE,provenance=list(descriptor=smf_to_list(distribution@uncertainty)))
}

#' Build a concise uncertainty report
#' @export
smf_uncertainty_report <- function(...) {
  xs<-list(...); cmp<-do.call(smf_uncertainty_compare,xs)
  list(table=cmp,semantics=smf_uncertainty_semantics(),warning="Intervals with different targets or probability statements must not be interpreted as interchangeable.")
}

S7::method(print, UncertaintyDecomposition) <- function(x, ...) { cat("<sciModelFlowR UncertaintyDecomposition>\n  method: ",x@method,"\n  identified: ",x@identified,"\n",sep=""); invisible(x) }
