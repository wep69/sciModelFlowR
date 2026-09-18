# Deep Learning package-native contracts and architecture grammar introduced in 0.6.0.

DLArchitecture <- S7::new_class(
  "DLArchitecture",
  properties = list(
    kind = S7::class_character,
    input_shape = S7::class_any,
    output_dim = S7::class_integer,
    parameters = S7::class_any,
    modality = S7::class_character,
    task = S7::class_character
  ),
  validator = function(self) {
    allowed <- c("mlp","cnn1d","cnn2d","rnn","lstm","gru","tcn","transformer","vit","autoencoder","vae","transfer","multimodal","multitask")
    problems <- character()
    if (length(self@kind) != 1L || !self@kind %in% allowed) problems <- c(problems, "@kind is not a supported Deep Learning architecture")
    if (length(self@output_dim) != 1L || is.na(self@output_dim) || self@output_dim < 1L) problems <- c(problems, "@output_dim must be at least 1")
    if (length(problems)) problems else NULL
  }
)

DLHistory <- S7::new_class(
  "DLHistory",
  properties = list(epoch=S7::class_integer, training=S7::class_any,
    validation=S7::class_any, learning_rate=S7::class_any, stopped_epoch=S7::class_integer,
    best_epoch=S7::class_integer, best_metric=S7::class_numeric)
)

DLCheckpoint <- S7::new_class(
  "DLCheckpoint",
  properties = list(path=S7::class_character, sha256=S7::class_character,
    metadata=S7::class_any, backend=S7::class_character, trusted=S7::class_logical)
)

DLFitResult <- S7::new_class(
  "DLFitResult",
  properties = list(spec=S7::class_any, architecture=S7::class_any,
    backend=S7::class_character, model=S7::class_any, history=S7::class_any,
    device=S7::class_character, precision=S7::class_character, seed=S7::class_integer,
    checkpoint=S7::class_any, training_hash=S7::class_character,
    validation_hash=S7::class_character, provenance=S7::class_any, warnings=S7::class_any)
)

DLEnsembleResult <- S7::new_class(
  "DLEnsembleResult",
  properties = list(members=S7::class_any, seeds=S7::class_integer,
    predictions=S7::class_any, distribution=S7::class_any,
    provenance=S7::class_any)
)

DLUncertaintyResult <- S7::new_class(
  "DLUncertaintyResult",
  properties = list(mean=S7::class_any, aleatoric=S7::class_any,
    epistemic=S7::class_any, total=S7::class_any, intervals=S7::class_any,
    descriptor=S7::class_any, provenance=S7::class_any)
)

DLGradientExplanation <- S7::new_class(
  "DLGradientExplanation",
  properties = list(method=S7::class_character, values=S7::class_any,
    target=S7::class_any, baseline=S7::class_any, layer=S7::class_character,
    causal_interpretation=S7::class_logical, provenance=S7::class_any)
)

.smf_dl_arch <- function(kind, input_shape, output_dim=1L, parameters=list(), modality="tabular", task="regression") {
  DLArchitecture(kind=.smf_scalar_chr(kind,"kind"), input_shape=as.integer(input_shape),
    output_dim=as.integer(output_dim), parameters=.smf_named_list(parameters,"parameters"),
    modality=.smf_scalar_chr(modality,"modality"), task=.smf_scalar_chr(task,"task"))
}

#' Declare a Deep Learning architecture
#' @export
smf_dl_architecture <- function(kind, input_shape, output_dim=1L, parameters=list(), modality="tabular", task="regression") {
  .smf_dl_arch(kind, input_shape, output_dim, parameters, modality, task)
}

#' Declare a multilayer perceptron
#' @export
smf_mlp <- function(input_dim, hidden=c(64L,32L), output_dim=1L, activation="relu", dropout=0, task="regression") {
  .smf_dl_arch("mlp", as.integer(input_dim), output_dim,
    list(hidden=as.integer(hidden), activation=activation, dropout=as.numeric(dropout)), "tabular", task)
}

#' Declare a one-dimensional convolutional network
#' @export
smf_cnn1d <- function(input_shape, channels=c(32L,64L), kernel_size=3L, output_dim=1L, dropout=0, task="regression") {
  .smf_dl_arch("cnn1d", input_shape, output_dim,
    list(channels=as.integer(channels), kernel_size=as.integer(kernel_size), dropout=as.numeric(dropout)), "sequence", task)
}

#' Declare a two-dimensional convolutional network
#' @export
smf_cnn2d <- function(input_shape, channels=c(16L,32L), kernel_size=3L, output_dim=1L, dropout=0, task="regression") {
  .smf_dl_arch("cnn2d", input_shape, output_dim,
    list(channels=as.integer(channels), kernel_size=as.integer(kernel_size), dropout=as.numeric(dropout)), "image", task)
}

#' Declare a recurrent neural network
#' @export
smf_rnn <- function(input_size, hidden_size=64L, layers=1L, output_dim=1L, bidirectional=FALSE, task="regression") {
  .smf_dl_arch("rnn", c(NA_integer_, as.integer(input_size)), output_dim,
    list(hidden_size=as.integer(hidden_size), layers=as.integer(layers), bidirectional=isTRUE(bidirectional)), "sequence", task)
}

#' Declare an LSTM network
#' @export
smf_lstm <- function(input_size, hidden_size=64L, layers=1L, output_dim=1L, bidirectional=FALSE, task="regression") {
  .smf_dl_arch("lstm", c(NA_integer_, as.integer(input_size)), output_dim,
    list(hidden_size=as.integer(hidden_size), layers=as.integer(layers), bidirectional=isTRUE(bidirectional)), "sequence", task)
}

#' Declare a GRU network
#' @export
smf_gru <- function(input_size, hidden_size=64L, layers=1L, output_dim=1L, bidirectional=FALSE, task="regression") {
  .smf_dl_arch("gru", c(NA_integer_, as.integer(input_size)), output_dim,
    list(hidden_size=as.integer(hidden_size), layers=as.integer(layers), bidirectional=isTRUE(bidirectional)), "sequence", task)
}

#' Declare a temporal convolutional network
#' @export
smf_tcn <- function(input_shape, channels=c(32L,32L), kernel_size=3L, dilation_base=2L, output_dim=1L, task="regression") {
  .smf_dl_arch("tcn", input_shape, output_dim,
    list(channels=as.integer(channels), kernel_size=as.integer(kernel_size), dilation_base=as.integer(dilation_base)), "sequence", task)
}

#' Declare a Transformer encoder model
#' @export
smf_transformer <- function(input_size, d_model=64L, heads=4L, layers=2L, ff_dim=128L, output_dim=1L, task="regression") {
  .smf_dl_arch("transformer", c(NA_integer_, as.integer(input_size)), output_dim,
    list(d_model=as.integer(d_model), heads=as.integer(heads), layers=as.integer(layers), ff_dim=as.integer(ff_dim)), "sequence", task)
}

#' Declare a Vision Transformer
#' @export
smf_vit <- function(input_shape, patch_size=16L, d_model=128L, heads=4L, layers=4L, output_dim=1L, task="classification") {
  .smf_dl_arch("vit", input_shape, output_dim,
    list(patch_size=as.integer(patch_size), d_model=as.integer(d_model), heads=as.integer(heads), layers=as.integer(layers)), "image", task)
}

#' Declare an autoencoder
#' @export
smf_autoencoder <- function(input_dim, latent_dim=8L, hidden=c(64L,32L)) {
  .smf_dl_arch("autoencoder", as.integer(input_dim), as.integer(input_dim),
    list(latent_dim=as.integer(latent_dim), hidden=as.integer(hidden)), "tabular", "reconstruction")
}

#' Declare a variational autoencoder
#' @export
smf_vae <- function(input_dim, latent_dim=8L, hidden=c(64L,32L), beta=1) {
  .smf_dl_arch("vae", as.integer(input_dim), as.integer(input_dim),
    list(latent_dim=as.integer(latent_dim), hidden=as.integer(hidden), beta=as.numeric(beta)), "tabular", "reconstruction")
}

#' Declare a transfer-learning architecture
#' @export
smf_transfer_learning <- function(base, output_dim=1L, freeze_base=TRUE, unfreeze_last=0L, task="regression") {
  .smf_dl_arch("transfer", integer(), output_dim,
    list(base=base, freeze_base=isTRUE(freeze_base), unfreeze_last=as.integer(unfreeze_last)), "generic", task)
}

#' Declare a multimodal fusion architecture
#' @export
smf_multimodal <- function(branches, fusion=c("concatenate","sum"), hidden=64L, output_dim=1L, task="regression") {
  fusion <- match.arg(fusion)
  if (!is.list(branches) || length(branches) < 2L) .smf_abort("MULTIMODAL_BRANCHES", "Multimodal architectures require at least two explicit branches.")
  .smf_dl_arch("multimodal", integer(), output_dim, list(branches=branches, fusion=fusion, hidden=as.integer(hidden)), "multimodal", task)
}

#' Declare a multitask architecture
#' @export
smf_multitask <- function(shared, heads, loss_weights=NULL) {
  if (!is.list(heads) || length(heads) < 2L || is.null(names(heads))) .smf_abort("MULTITASK_HEADS", "Multitask architectures require at least two named heads.")
  if (is.null(loss_weights)) loss_weights <- stats::setNames(rep(1, length(heads)), names(heads))
  .smf_dl_arch("multitask", integer(), as.integer(length(heads)), list(shared=shared, heads=heads, loss_weights=loss_weights), "multitask", "multitask")
}
