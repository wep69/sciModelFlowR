# Gradient-based Deep Learning explanations. All are explicitly non-causal.

.smf_dl_gradient_input <- function(object, x, target_index=1L) {
  .smf_require_torch()
  if (!S7::S7_inherits(object,DLFitResult)) cli::cli_abort("{.arg object} must be a DLFitResult.")
  tx <- .smf_dl_tensor(x,object@device); tx$requires_grad_(TRUE); object@model$eval()
  out <- object@model(tx); score <- out[,as.integer(target_index)]$sum(); score$backward()
  list(input=tx, gradient=tx$grad$clone()$detach())
}

#' Compute input-gradient saliency
#' @export
smf_dl_saliency <- function(object, x, target_index=1L) {
  z <- .smf_dl_gradient_input(object,x,target_index)
  DLGradientExplanation(method="saliency", values=as.array(z$gradient$to(device="cpu")), target=as.integer(target_index), baseline=NULL, layer=character(), causal_interpretation=FALSE,
    provenance=list(backend="torch", warning="Gradient saliency is a local sensitivity description, not a causal effect."))
}

#' Compute Integrated Gradients
#' @export
smf_dl_integrated_gradients <- function(object, x, baseline=NULL, steps=50L, target_index=1L) {
  .smf_require_torch(); x <- as.array(x); if (is.null(baseline)) baseline <- array(0,dim=dim(x))
  if (!identical(dim(x),dim(baseline))) cli::cli_abort("baseline must have the same dimensions as x.")
  alphas <- seq(0,1,length.out=as.integer(steps)+1L)[-1L]; grads <- vector("list",length(alphas))
  for (i in seq_along(alphas)) {
    xi <- baseline + alphas[[i]]*(x-baseline); grads[[i]] <- as.array(.smf_dl_gradient_input(object,xi,target_index)$gradient$to(device="cpu"))
  }
  avg <- Reduce(`+`,grads)/length(grads); val <- (x-baseline)*avg
  DLGradientExplanation(method="integrated_gradients", values=val, target=as.integer(target_index), baseline=baseline, layer=character(), causal_interpretation=FALSE,
    provenance=list(steps=as.integer(steps),backend="torch"))
}

#' Compute gradient times input
#' @export
smf_dl_gradient_x_input <- function(object, x, target_index=1L) {
  z <- .smf_dl_gradient_input(object,x,target_index); val <- as.array(z$gradient$to(device="cpu"))*as.array(x)
  DLGradientExplanation(method="gradient_x_input", values=val, target=as.integer(target_index), baseline=NULL, layer=character(), causal_interpretation=FALSE, provenance=list(backend="torch"))
}

#' Compute Grad-CAM when a compatible activation adapter is supplied
#' @export
smf_dl_gradcam <- function(object, x, layer, target_index=1L, activation_adapter=NULL) {
  if (is.null(activation_adapter) || !is.function(activation_adapter)) {
    .smf_abort("GRADCAM_ADAPTER_REQUIRED", "Grad-CAM requires an explicit activation adapter that returns activations and gradients for the declared convolutional layer.")
  }
  z <- activation_adapter(object=object,x=x,layer=layer,target_index=as.integer(target_index))
  if (!is.list(z) || is.null(z$activations) || is.null(z$gradients)) .smf_abort("GRADCAM_ADAPTER_INVALID", "The Grad-CAM adapter must return activations and gradients.")
  a <- as.array(z$activations); g <- as.array(z$gradients)
  axes <- seq_along(dim(g)); spatial <- axes[-c(1L,2L)]; w <- if(length(spatial)) apply(g,c(1L,2L),mean) else g
  cam <- pmax(0,apply(a*w,c(1L,spatial),sum))
  DLGradientExplanation(method="gradcam", values=cam, target=as.integer(target_index), baseline=NULL, layer=.smf_scalar_chr(layer,"layer"), causal_interpretation=FALSE,
    provenance=list(adapter="explicit",backend="torch"))
}
