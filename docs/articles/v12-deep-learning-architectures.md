# Deep Learning Architectures for Tabular, Spectral, Image, and Sequential Data

**Package:** `sciModelFlowR`\
**Version targeted:** `0.6.0`\
**Status:** source-complete; runtime validation deferred to the
consolidated local validation cycle.

> The code blocks are designed for local execution after optional Deep
> Learning backends are installed. The package does not require `torch`,
> `luz`, or `keras3` merely to load the core scientific workflow.

## 1 1. Architecture follows data geometry

This vignette is an architecture-selection guide. It does not rank
neural networks universally.

## 2 2. Learning objectives

The reader should be able to choose among MLP, CNN, recurrent,
temporal-convolutional and attention architectures; reshape sequences
safely; understand transfer, multimodal and multitask interfaces; and
identify when a simpler model is preferable.

## 3 3. Architecture map

| Data geometry | Starting architecture | Escalate when |
|----|----|----|
| fixed predictor vector | [`smf_mlp()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | strong nonlinear interactions remain |
| spectrum / local 1D signal | [`smf_cnn1d()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | local wavelength or time motifs matter |
| image | [`smf_cnn2d()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | spatial texture matters |
| ordered sequence | [`smf_rnn()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | basic state dependence is adequate |
| long-memory sequence | [`smf_lstm()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) / [`smf_gru()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | longer dependencies are plausible |
| temporal signal | [`smf_tcn()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | dilated local context is useful |
| long sequence | [`smf_transformer()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | global attention is justified |
| image patches | [`smf_vit()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | sample size supports attention models |
| representation learning | [`smf_autoencoder()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | compression/reconstruction is the target |
| generative latent representation | [`smf_vae()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md) | distributional latent space is needed |

## 4 4. MLP for tabular scientific data

``` r

mlp <- smf_mlp(
  input_dim = 12,
  output_dim = 1,
  hidden = c(128, 64, 32),
  dropout = 0.15
)
```

An MLP does not eliminate the need for leakage-safe preprocessing or
design-aware resampling.

## 5 5. One-dimensional CNN

``` r

cnn1 <- smf_cnn1d(
  channels = 1,
  length = 256,
  output_dim = 1,
  filters = c(32, 64, 128),
  kernel_size = 5
)
```

For spectroscopy, a convolution can encode local wavelength
neighborhoods. The preprocessing must preserve the spectral axis.

## 6 6. Two-dimensional CNN

``` r

cnn2 <- smf_cnn2d(
  channels = 3,
  height = 128,
  width = 128,
  output_dim = 4,
  task = "classification"
)
```

Train/validation splits should usually occur at the biological or
experimental-unit level, not at the pixel level.

## 7 7. Sequence data must be reshaped explicitly

``` r

s <- smf_load_dataset("gold_dl_sequence")

# The package-native tensor trainer expects an explicit
# observation x sequence x feature array. Construct that array after
# verifying sequence IDs, time order, equal lengths, and feature roles.
ids <- unique(s$sequence_id)
steps <- sort(unique(s$time))
features <- c("signal", "covariate")
x_seq <- array(NA_real_, dim = c(length(ids), length(steps), length(features)))

for (i in seq_along(ids)) {
  z <- s[s$sequence_id == ids[i], ]
  z <- z[order(z$time), ]
  stopifnot(identical(z$time, steps))
  x_seq[i, , ] <- as.matrix(z[, features])
}

dim(x_seq)
```

The explicit construction should refuse unequal sequence lengths rather
than silently truncating or reordering them.

## 8 8. RNN

``` r

rnn <- smf_rnn(
  input_dim = 3,
  output_dim = 1,
  hidden_dim = 64
)
```

## 9 9. LSTM

``` r

lstm <- smf_lstm(
  input_dim = 3,
  output_dim = 1,
  hidden_dim = 64,
  layers = 2,
  dropout = 0.15
)
```

## 10 10. GRU

``` r

gru <- smf_gru(
  input_dim = 3,
  output_dim = 1,
  hidden_dim = 64
)
```

LSTM and GRU should be compared under the same resampling geometry and
training budget.

## 11 11. Temporal convolutional network

``` r

tcn <- smf_tcn(
  channels = 3,
  length = 24,
  output_dim = 1,
  filters = c(32, 32, 64),
  dilations = c(1, 2, 4)
)
```

Dilations enlarge the temporal receptive field without recurrence.

## 12 12. Transformer encoder

``` r

tr <- smf_transformer(
  input_dim = 3,
  output_dim = 1,
  d_model = 64,
  heads = 4,
  layers = 2
)
```

Attention is not automatically superior to recurrence. Its flexibility
must be supported by enough data and a scientifically meaningful
sequence representation.

## 13 13. Vision Transformer

``` r

vit <- smf_vit(
  channels = 3,
  height = 128,
  width = 128,
  output_dim = 4,
  patch_size = 16,
  task = "classification"
)
```

Patch size changes the effective spatial resolution seen by the model
and must be recorded.

## 14 14. Autoencoder

``` r

ae <- smf_autoencoder(
  input_dim = 100,
  latent_dim = 8,
  hidden = c(64, 32)
)
```

A low reconstruction loss does not guarantee that the latent
representation is useful for the scientific endpoint.

## 15 15. Variational autoencoder

``` r

vae <- smf_vae(
  input_dim = 100,
  latent_dim = 8,
  beta = 1
)
```

The VAE objective balances reconstruction and regularization of the
latent distribution. The latent dimensions should not be assigned
biological meanings without validation.

## 16 16. Transfer learning

``` r

# transfer <- smf_transfer_learning(
#   base_model = pretrained_extractor,
#   output_dim = 1,
#   freeze = TRUE,
#   parameters = list(feature_dim = 512)
# )
```

The source model and preprocessing convention are part of provenance.

## 17 17. Multimodal interface

``` r

weather <- smf_mlp(20, 16)
soil    <- smf_mlp(12, 16)

mm <- smf_multimodal(
  branches = list(weather = weather, soil = soil),
  output_dim = 1,
  fusion = "concatenate"
)
```

Alignment of modalities must occur by the prediction unit, not by row
position alone.

## 18 18. Multitask interface

``` r

shared <- smf_mlp(20, 32)

mt <- smf_multitask(
  shared,
  heads = list(
    yield = list(output_dim = 1),
    stress = list(output_dim = 3)
  )
)
```

A multitask objective is justified when tasks share useful
representation structure and all required labels are available under the
intended deployment scenario.

## 19 19. Building torch modules

``` r

# Torch modules are constructed internally by the package-native trainer.
# Architecture declaration itself remains backend-independent.
mlp
```

Architecture declaration remains available when `torch` is absent.

## 20 20. Model complexity and sample size

Parameter count is not a universal complexity metric, but it is a useful
diagnostic. Compare training stability and held-out performance as
capacity increases.

## 21 21. Spatial and temporal leakage

For images, patches from one plant or plot should not be split across
train and test unless the estimand truly concerns new patches from known
units. For sequences, future observations must not leak into earlier
training windows.

## 22 22. Architecture selection sequence

1.  define the prediction unit;
2.  identify data geometry;
3.  create the simplest architecture that respects that geometry;
4.  validate tensor construction;
5.  establish a baseline;
6.  add capacity only when diagnostics identify underfitting;
7.  compare under identical resampling;
8.  confirm externally when possible.

## 23 23. Common mistakes

- flattening images before checking whether spatial structure matters;
- using CNN patches as independent replicates;
- shuffling time before recurrent training;
- applying a Transformer because the sequence is long without checking
  sample size;
- interpreting VAE axes as traits without external evidence;
- mixing modalities that were measured at incompatible units.

## 24 24. Suggested architecture experiments

A useful teaching exercise is to compare MLP, TCN, GRU and Transformer
models on the same synthetic sequence problem while holding the outer
split fixed. The goal is not to crown a winner but to examine how
inductive bias, parameter count and training variability change the
result.

## 25 25. Final perspective

Neural architectures encode assumptions about information flow. Choosing
an architecture is therefore part of scientific model specification.

#### 25.0.1 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.2 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.3 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.4 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.5 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.6 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.7 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.8 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.9 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.10 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.11 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.12 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.13 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.14 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.15 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.16 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.17 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.18 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.19 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.20 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.21 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.22 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.23 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.24 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.25 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.26 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.27 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.28 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.29 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.30 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.31 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.32 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.33 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.34 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.35 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.36 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.37 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.38 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.39 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.40 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.41 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.42 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.43 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.44 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.45 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.46 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.47 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.48 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.49 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.50 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.51 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.52 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.53 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.54 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.55 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.56 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.57 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.58 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.59 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.60 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.61 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.62 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.63 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.64 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.65 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.66 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.67 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.68 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

#### 25.0.69 Scientific interpretation note

Architectural choice should follow the geometry of the data. An MLP is
appropriate for a fixed vector of predictors; a one-dimensional CNN can
learn local spectral or temporal motifs; a two-dimensional CNN can
exploit local image structure; recurrent models encode ordered state
transitions; TCNs use causal or dilated convolutions; Transformers use
attention to connect positions more directly. These are not
interchangeable labels for ‘more complex model’. Each imposes a
different inductive bias.

#### 25.0.70 Scientific interpretation note

Sequence models require an explicit tensor grammar. The package does not
silently turn long-format repeated observations into a three-dimensional
array because doing so can reorder times, combine experimental units, or
truncate unequal sequences. the analyst must explicitly name the
sequence identifier, time variable and features when constructing the
tensor, and unequal lengths require a declared padding or masking
strategy rather than silent truncation.

#### 25.0.71 Scientific interpretation note

Transfer learning is represented as an interface rather than a promise
that any pretrained model is scientifically suitable. Freezing a feature
extractor can reduce the effective number of trainable parameters, but
the source domain, preprocessing convention, image scale, spectral
range, and outcome definition still matter. Fine-tuning should be
evaluated against a simpler frozen baseline, with leakage-safe
resampling and an explicit record of which layers were trainable.

#### 25.0.72 Scientific interpretation note

Multimodal and multitask models are especially vulnerable to hidden
target leakage. Modalities can be synchronized at different biological
scales, and one task can inadvertently expose information that would not
be available at prediction time for another. The package therefore asks
for named branches and named heads. Fusion and task heads are part of
the architecture record, rather than unnamed tensors passed to a generic
training function.

### 25.1 Architecture shape contracts are executable

Architecture declarations are not labels attached after model
construction.
[`smf_dl_train_tensor()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md)
checks the input array against the architecture contract before
training: MLP/AE/VAE expect a feature dimension; CNN1D and TCN expect
channel × length; CNN2D and ViT expect channel × height × width;
RNN/LSTM/GRU/Transformer expect sequence × feature after the observation
dimension. This explicit contract prevents a common silent error in
scientific applications, where spectral bands, time steps, channels, or
image axes are transposed until a backend accepts them. When data
require a different orientation, the analyst must transform it
deliberately and record that transformation.
