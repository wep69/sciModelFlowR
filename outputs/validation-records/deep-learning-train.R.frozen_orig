# Optional torch execution layer. The package core does not import torch.

.smf_require_torch <- function() {
  if (!requireNamespace("torch", quietly=TRUE)) {
    .smf_abort("TORCH_NOT_AVAILABLE", "The optional package 'torch' is required for this Deep Learning operation.", class="smf_capability_error")
  }
  invisible(TRUE)
}

.smf_dl_validation_role <- function(role) {
  role <- .smf_scalar_chr(role, "validation_role")
  if (role %in% c("final_test","external_test")) {
    .smf_abort("TEST_DATA_IN_DL_VALIDATION", "Final or external test data cannot drive early stopping, scheduling, or checkpoint selection.", evidence=list(role=role), class="smf_leakage_error")
  }
  role
}

.smf_dl_validate_shape <- function(x, architecture) {
  if (!inherits(dim(x), "integer") && is.null(dim(x))) .smf_abort("DL_TENSOR_SHAPE", "Structured Deep Learning input must have dimensions.")
  expected <- architecture@input_shape
  observed <- dim(x)[-1L]
  if (length(expected) && length(observed) != length(expected)) {
    .smf_abort("DL_TENSOR_SHAPE", "Tensor rank does not match the declared architecture input shape.", evidence=list(expected=expected, observed=observed))
  }
  if (length(expected)) {
    fixed <- !is.na(expected)
    if (any(fixed) && any(observed[fixed] != expected[fixed])) {
      .smf_abort("DL_TENSOR_SHAPE", "Tensor dimensions do not match the declared architecture input shape.", evidence=list(expected=expected, observed=observed))
    }
  }
  invisible(TRUE)
}

#' Define a Deep Learning optimizer
#' @export
smf_dl_optimizer <- function(name=c("adam","adamw","sgd","rmsprop"), lr=1e-3, weight_decay=0, momentum=0.9, parameters=list()) {
  name <- match.arg(name)
  list(name=name, lr=as.numeric(lr), weight_decay=as.numeric(weight_decay), momentum=as.numeric(momentum), parameters=parameters)
}

#' Define a Deep Learning learning-rate scheduler
#' @export
smf_dl_scheduler <- function(name=c("none","step","cosine","plateau"), parameters=list()) {
  list(name=match.arg(name), parameters=.smf_named_list(parameters,"parameters"))
}

#' Define early stopping
#' @export
smf_dl_early_stopping <- function(monitor="validation_loss", mode=c("min","max"), patience=10L, min_delta=0, restore_best=TRUE) {
  list(monitor=.smf_scalar_chr(monitor,"monitor"), mode=match.arg(mode), patience=as.integer(patience), min_delta=as.numeric(min_delta), restore_best=isTRUE(restore_best))
}

#' Resolve the Deep Learning device policy
#' @export
smf_dl_device <- function(device=c("auto","cpu","cuda")) {
  device <- match.arg(device)
  if (device == "auto") {
    if (requireNamespace("torch", quietly=TRUE) && isTRUE(tryCatch(torch::cuda_is_available(), error=function(e) FALSE))) "cuda" else "cpu"
  } else if (device == "cuda") {
    .smf_require_torch()
    if (!isTRUE(torch::cuda_is_available())) .smf_abort("CUDA_NOT_AVAILABLE", "CUDA was requested but is not available.", class="smf_capability_error")
    "cuda"
  } else "cpu"
}

#' Declare the Deep Learning determinism policy
#' @export
smf_dl_determinism <- function(mode=c("reproducible","strict_cpu","performance"), seed=260915L) {
  list(mode=match.arg(mode), seed=as.integer(seed), bitwise_gpu=FALSE,
    note="GPU kernels and mixed precision are not claimed to be bitwise identical across devices.")
}

#' Declare mixed-precision policy
#' @export
smf_dl_mixed_precision <- function(precision=c("float32","mixed16","float64"), device="auto") {
  precision <- match.arg(precision)
  dev <- smf_dl_device(device)
  if (precision == "mixed16" && dev != "cuda") .smf_abort("MIXED16_UNSUPPORTED_DEVICE", "mixed16 is supported by the package-native trainer only on CUDA devices.")
  list(precision=precision, device=dev, autocast=identical(precision,"mixed16"), gradient_scaler=identical(precision,"mixed16"))
}

.smf_dl_build_simple_module <- function(architecture) {
  .smf_require_torch()
  kind <- architecture@kind
  p <- architecture@parameters
  if (kind == "mlp") {
    input_dim <- as.integer(architecture@input_shape[[1L]])
    hidden <- p$hidden %||% c(64L,32L)
    output_dim <- architecture@output_dim
    Net <- torch::nn_module(
      "SMFMLP",
      initialize=function() {
        dims <- c(input_dim, hidden, output_dim)
        self$layers <- torch::nn_module_list(lapply(seq_len(length(dims)-1L), function(i) torch::nn_linear(dims[[i]], dims[[i+1L]])))
        self$dropout <- torch::nn_dropout(p$dropout %||% 0)
      },
      forward=function(x) {
        n <- length(self$layers)
        for (i in seq_len(n)) {
          x <- self$layers[[i]](x)
          if (i < n) { x <- torch::nnf_relu(x); x <- self$dropout(x) }
        }
        x
      }
    )
    return(Net())
  }
  # Structured architectures use a validated generic projection in the initial
  # package-native execution path. Architecture-specific adapters may replace it.
  FlatNet <- torch::nn_module(
    "SMFStructuredProjection",
    initialize=function() {
      self$flatten <- torch::nn_flatten(start_dim=2L)
      self$lazy <- torch::nn_lazy_linear(architecture@output_dim)
    },
    forward=function(x) self$lazy(self$flatten(x))
  )
  FlatNet()
}

.smf_dl_tensor <- function(x, device="cpu") {
  .smf_require_torch()
  t <- torch::torch_tensor(x, dtype=torch::torch_float())
  if (device == "cuda") t <- t$cuda()
  t
}

.smf_dl_target_tensor <- function(y, device="cpu") {
  t <- .smf_dl_tensor(as.matrix(y), device)
  if (length(dim(t)) == 1L) t <- t$unsqueeze(2)
  t
}

.smf_dl_train_engine <- function(x, y, architecture, validation=NULL, validation_role="analysis_validation",
                                 epochs=100L, batch_size=32L, optimizer=smf_dl_optimizer(), scheduler=smf_dl_scheduler(),
                                 early_stopping=smf_dl_early_stopping(), device="auto", precision="float32",
                                 seed=260915L, gradient_clip=NULL, checkpoint=NULL, callbacks=list()) {
  .smf_require_torch(); .smf_dl_validation_role(validation_role)
  dev <- smf_dl_device(device); mp <- smf_dl_mixed_precision(precision, dev)
  if (!is.null(validation)) {
    if (!is.list(validation) || is.null(validation$x) || is.null(validation$y)) .smf_abort("DL_VALIDATION_FORMAT", "validation must be a list with x and y.")
    .smf_dl_validate_shape(validation$x, architecture)
  }
  .smf_dl_validate_shape(x, architecture)
  set.seed(as.integer(seed)); try(torch::torch_manual_seed(as.integer(seed)), silent=TRUE)
  model <- .smf_dl_build_simple_module(architecture)
  if (dev == "cuda") model <- model$cuda()
  opt <- switch(optimizer$name,
    adam=torch::optim_adam(model$parameters, lr=optimizer$lr, weight_decay=optimizer$weight_decay),
    adamw=torch::optim_adamw(model$parameters, lr=optimizer$lr, weight_decay=optimizer$weight_decay),
    sgd=torch::optim_sgd(model$parameters, lr=optimizer$lr, momentum=optimizer$momentum, weight_decay=optimizer$weight_decay),
    rmsprop=torch::optim_rmsprop(model$parameters, lr=optimizer$lr, momentum=optimizer$momentum, weight_decay=optimizer$weight_decay))
  tx <- .smf_dl_tensor(x, dev); ty <- .smf_dl_target_tensor(y, dev)
  n <- dim(x)[1L]; history <- data.frame(epoch=integer(), training_loss=numeric(), validation_loss=numeric())
  best <- Inf; best_epoch <- 0L; bad <- 0L
  for (ep in seq_len(as.integer(epochs))) {
    model$train(); ord <- sample.int(n)
    losses <- numeric()
    for (start in seq(1L, n, by=as.integer(batch_size))) {
      idx <- ord[start:min(start+as.integer(batch_size)-1L,n)]
      opt$zero_grad(); pred <- model(tx[idx]); loss <- torch::nnf_mse_loss(pred, ty[idx]); loss$backward()
      if (!is.null(gradient_clip)) torch::nn_utils_clip_grad_norm_(model$parameters, as.numeric(gradient_clip))
      opt$step(); losses <- c(losses, as.numeric(loss$item()))
    }
    vloss <- NA_real_
    if (!is.null(validation)) {
      model$eval(); vx <- .smf_dl_tensor(validation$x, dev); vy <- .smf_dl_target_tensor(validation$y, dev)
      vp <- model(vx); vloss <- as.numeric(torch::nnf_mse_loss(vp, vy)$item())
    }
    score <- if (is.finite(vloss)) vloss else mean(losses)
    history <- rbind(history, data.frame(epoch=ep, training_loss=mean(losses), validation_loss=vloss))
    if (score < best - early_stopping$min_delta) { best <- score; best_epoch <- ep; bad <- 0L } else bad <- bad + 1L
    if (length(callbacks)) for (cb in callbacks) if (is.function(cb)) cb(list(epoch=ep, model=model, score=score))
    if (bad >= early_stopping$patience) break
  }
  h <- DLHistory(epoch=as.integer(history$epoch), training=history$training_loss,
    validation=history$validation_loss, learning_rate=rep(optimizer$lr,nrow(history)),
    stopped_epoch=as.integer(tail(history$epoch,1)), best_epoch=as.integer(best_epoch), best_metric=as.numeric(best))
  ck <- NULL
  if (!is.null(checkpoint)) ck <- smf_dl_save_checkpoint(model, checkpoint, metadata=list(epoch=best_epoch, architecture=smf_to_list(architecture)))
  DLFitResult(spec=NULL, architecture=architecture, backend="torch", model=model, history=h,
    device=dev, precision=precision, seed=as.integer(seed), checkpoint=ck,
    training_hash=digest::digest(x,algo="sha256"), validation_hash=if(is.null(validation)) character() else digest::digest(validation$x,algo="sha256"),
    provenance=list(validation_role=validation_role, optimizer=optimizer, scheduler=scheduler, mixed_precision=mp), warnings=list())
}

#' Train a tabular Deep Learning model with torch
#' @export
smf_dl_train <- function(x, y, architecture=NULL, validation=NULL, validation_role="analysis_validation", epochs=100L, batch_size=32L,
                         optimizer=smf_dl_optimizer(), scheduler=smf_dl_scheduler(), early_stopping=smf_dl_early_stopping(),
                         device="auto", precision="float32", seed=260915L, gradient_clip=NULL, checkpoint=NULL, callbacks=list()) {
  x <- as.matrix(x); if (is.null(architecture)) architecture <- smf_mlp(ncol(x))
  .smf_dl_train_engine(x, y, architecture, validation, validation_role, epochs, batch_size, optimizer, scheduler, early_stopping, device, precision, seed, gradient_clip, checkpoint, callbacks)
}

#' Train an N-dimensional tensor Deep Learning model with torch
#' @export
smf_dl_train_tensor <- function(x, y, architecture, validation=NULL, validation_role="analysis_validation", epochs=100L, batch_size=32L,
                                optimizer=smf_dl_optimizer(), scheduler=smf_dl_scheduler(), early_stopping=smf_dl_early_stopping(),
                                device="auto", precision="float32", seed=260915L, gradient_clip=NULL, checkpoint=NULL, callbacks=list()) {
  .smf_dl_train_engine(x, y, architecture, validation, validation_role, epochs, batch_size, optimizer, scheduler, early_stopping, device, precision, seed, gradient_clip, checkpoint, callbacks)
}

#' Predict with a tabular Deep Learning fit
#' @export
smf_dl_predict <- function(object, newdata) {
  x <- as.matrix(newdata); smf_dl_predict_tensor(object, x)
}

#' Predict with a tensor Deep Learning fit
#' @export
smf_dl_predict_tensor <- function(object, x) {
  if (!S7::S7_inherits(object, DLFitResult)) cli::cli_abort("{.arg object} must be a DLFitResult.")
  .smf_dl_validate_shape(x, object@architecture); .smf_require_torch()
  object@model$eval(); tx <- .smf_dl_tensor(x, object@device); pred <- object@model(tx)
  as.array(pred$to(device="cpu"))
}

#' Create checkpoint metadata
#' @export
smf_dl_checkpoint <- function(path, backend="torch", metadata=list(), trusted=FALSE) {
  path <- normalizePath(path, mustWork=FALSE)
  sha <- if (file.exists(path)) digest::digest(file=path, algo="sha256") else character()
  DLCheckpoint(path=path, sha256=sha, metadata=metadata, backend=backend, trusted=isTRUE(trusted))
}

#' Save a Deep Learning checkpoint
#' @export
smf_dl_save_checkpoint <- function(model, path, metadata=list()) {
  .smf_require_torch(); dir.create(dirname(path), recursive=TRUE, showWarnings=FALSE)
  torch::torch_save(model$state_dict(), path)
  smf_dl_checkpoint(path, backend="torch", metadata=metadata, trusted=FALSE)
}

#' Load a Deep Learning checkpoint with explicit trust
#' @export
smf_dl_load_checkpoint <- function(checkpoint, model, trusted=FALSE, verify_hash=TRUE) {
  .smf_require_torch()
  if (!isTRUE(trusted)) .smf_abort("UNTRUSTED_CHECKPOINT", "Backend checkpoint deserialization is disabled by default; set trusted = TRUE only for a checkpoint you trust.", class="smf_serialization_error")
  if (!S7::S7_inherits(checkpoint, DLCheckpoint)) cli::cli_abort("{.arg checkpoint} must be a DLCheckpoint.")
  if (isTRUE(verify_hash) && length(checkpoint@sha256)) {
    now <- digest::digest(file=checkpoint@path, algo="sha256")
    if (!identical(tolower(now),tolower(checkpoint@sha256))) .smf_abort("CHECKPOINT_HASH_MISMATCH", "Checkpoint SHA-256 does not match its metadata.", class="smf_serialization_error")
  }
  state <- torch::torch_load(checkpoint@path); model$load_state_dict(state); model
}

#' Resume a model from a trusted checkpoint
#' @export
smf_dl_resume <- function(object, checkpoint, trusted=FALSE, verify_hash=TRUE) {
  if (!S7::S7_inherits(object, DLFitResult)) cli::cli_abort("{.arg object} must be a DLFitResult.")
  object@model <- smf_dl_load_checkpoint(checkpoint, object@model, trusted=trusted, verify_hash=verify_hash)
  object@checkpoint <- checkpoint
  object@provenance$resumed_from <- checkpoint@sha256
  object
}
