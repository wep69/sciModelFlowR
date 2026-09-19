# Deep Learning Foundations: Training, Reproducibility, and Scientific Safeguards

**Package:** `sciModelFlowR`\
**Version targeted:** `0.6.0`\
**Status:** source-complete; runtime validation deferred to the
consolidated local validation cycle.

> The code blocks are designed for local execution after optional Deep
> Learning backends are installed. The package does not require `torch`,
> `luz`, or `keras3` merely to load the core scientific workflow.

## 1 1. Why Deep Learning is a separate workflow layer

Version 0.6.0 introduces Deep Learning without changing the rule that
has governed every earlier release: **design before algorithm,
leakage-safe development, diagnosis before interpretation, and explicit
uncertainty**.

## 2 2. Learning objectives

After this vignette, the reader should be able to:

1.  decide when representation learning adds a scientific capability;
2.  declare a package-native architecture and training specification;
3.  distinguish training, validation and final-test roles;
4.  configure optimizer, scheduler, minibatch, early stopping and
    gradient clipping;
5.  declare CPU/GPU and precision policies;
6.  understand deterministic versus best-effort reproducibility;
7.  save and reload checkpoints with explicit trust;
8.  inspect training history and manifest information;
9.  use the Gold nonlinear fixture without leaking generator-truth
    columns;
10. report the training process as part of the scientific method.

## 3 3. Inspect the Deep Learning environment

``` r

library(sciModelFlowR)
smf_dl_device("auto")
smf_doctor()
```

`torch`, `luz`, `keras3` and `torchvision` are optional. The core
package should still load when none is installed.

## 4 4. The architecture contract

``` r

arch <- smf_mlp(
  input_dim = 6,
  output_dim = 1,
  hidden = c(128, 64),
  activation = "relu",
  dropout = 0.15,
  task = "regression"
)
arch
```

The object is descriptive. It can be serialized before a backend module
exists.

## 5 5. The training contract

``` r

dl <- smf_dl_spec(
  architecture = arch,
  trainer = "torch",
  optimizer = "adamw",
  scheduler = "cosine",
  precision = "float32",
  device = "cpu",
  epochs = 100,
  batch_size = 32,
  early_stopping = TRUE,
  patience = 12,
  min_delta = 1e-4,
  gradient_clip = 1,
  checkpoint = TRUE,
  deterministic = "strict_cpu",
  seed = 260915,
  parameters = list(
    learning_rate = 1e-3,
    weight_decay = 1e-4
  )
)
```

### 5.1 5.1 Why validation is development data

The validation split can influence stopping, scheduling and model
selection. It is therefore not an unbiased final evaluation sample.

## 6 6. Gold data for the first CPU workflow

``` r

d <- smf_load_dataset("gold_dl_nonlinear")
predictors <- paste0("x", 1:6)

# truth_mu and truth_sigma are generator-truth columns.
# They are excluded from model inputs.
fit <- smf_dl_train(
  data = d,
  target = "y",
  architecture = arch,
  spec = dl,
  predictors = predictors,
  task = "regression"
)
```

## 7 7. Training history

``` r

hist <- fit@history
head(hist)
tail(hist)
```

A falling training loss is not sufficient evidence that the model
generalizes. The validation curve, stopping epoch and resampling
performance must be interpreted together.

## 8 8. Optimizers and learning-rate schedules

The 0.6.0 trainer recognizes Adam, AdamW, SGD and RMSProp. A
learning-rate schedule is part of the fitted procedure, not a post-hoc
plotting choice.

``` r

dl_step <- smf_dl_spec(
  arch,
  optimizer = "sgd",
  scheduler = "step",
  epochs = 120,
  parameters = list(
    learning_rate = 0.01,
    momentum = 0.9,
    step_size = 30L,
    gamma = 0.5
  )
)
```

## 9 9. Gradient clipping

Gradient clipping can stabilize training in recurrent or otherwise
unstable models, but it can also change the effective optimization
dynamics. Record the threshold.

## 10 10. Mixed precision

`precision = "mixed16"` requests automatic mixed precision on CUDA. It
is not silently emulated on CPU. The scientific record should state
whether AMP was used because the numerical trajectory can differ from
full precision.

## 11 11. Device policy

`device = "auto"` prefers CUDA when available, otherwise CPU. For
cross-platform reference tests, explicit `device = "cpu"` is preferable.

## 12 12. Determinism

The package distinguishes:

- `strict_cpu`: strongest reference policy offered by 0.6.0;
- `seeded`: seeds are controlled, but backend kernels may differ;
- `best_effort`: deterministic settings are requested when feasible;
- `backend_default`: no additional guarantee beyond recorded seeds.

A seed is necessary for repeatability but does not imply bitwise
equivalence across operating systems, CPU instruction sets, GPU devices
or backend versions.

## 13 13. Checkpointing

``` r

ck <- fit@checkpoint
ck

# Loading backend serialization requires explicit trust.
model2 <- smf_dl_load_checkpoint(
  ck,
  architecture = arch,
  trusted = TRUE,
  device = "cpu"
)
```

The JSON sidecar is safe metadata. The backend `.pt` object is treated
as opaque serialization and is not loaded by default.

## 14 14. Resume semantics

Resuming an optimization trajectory differs from loading weights for
transfer learning. `resume = TRUE` expects a checkpoint and explicit
`trusted_resume = TRUE`; when available, optimizer and scheduler state
are restored with the model state.

## 15 15. Optional higher-level trainers

`luz` remains an optional ecosystem dependency, but version 0.6.0 does
not expose a separate public `luz` trainer that could silently redefine
batching, losses, or validation. The package-native `torch` trainer is
the executable reference pathway. A future `luz` adapter must satisfy
the same data-boundary and provenance contracts before certification.

## 16 16. Optional keras3 adapter

Backend selection for Keras must occur before the model is built.
`sciModelFlowR` does not switch TensorFlow/JAX/PyTorch backends inside a
scientific run.

## 17 17. Diagnostics before interpretation

At minimum inspect:

- training and validation loss trajectories;
- the epoch selected by early stopping;
- residual/prediction diagnostics on resampled assessment data;
- sensitivity to initialization;
- sensitivity to architecture complexity;
- calibration for probabilistic outputs;
- computational failures or NaNs.

## 18 18. Minimum reporting block

A manuscript should record architecture, parameter count when available,
preprocessing, optimizer, learning rate, scheduler, batch size, epochs,
early stopping rule, checkpoint policy, device, precision, seed policy
and resampling scheme.

## 19 19. Common mistakes

### 19.1 19.1 Using final test data for early stopping

This converts the final test into development data.

### 19.2 19.2 Reporting only the best epoch

The stopping rule and full validation trajectory matter.

### 19.3 19.3 Comparing GPU and CPU runs as if seed equality implied bitwise equality

The determinism guarantee is backend-dependent.

### 19.4 19.4 Treating a larger network as a stronger scientific model

Capacity is useful only when supported by data volume, structure and
external validation.

## 20 20. Integrated first workflow

``` r

d <- smf_load_dataset("gold_dl_nonlinear")

arch <- smf_mlp(
  6, 1,
  hidden = c(64, 32),
  dropout = 0.10,
  task = "regression"
)

spec <- smf_dl_spec(
  architecture = arch,
  device = "cpu",
  epochs = 60,
  batch_size = 32,
  patience = 8,
  deterministic = "strict_cpu",
  parameters = list(learning_rate = 0.002)
)

fit <- smf_dl_train(
  d,
  target = "y",
  architecture = arch,
  spec = spec,
  predictors = paste0("x", 1:6),
  task = "regression"
)

pred <- smf_dl_predict(fit, d[1:20, ])
hist <- fit@history
```

## 21 21. Final perspective

The central object of Deep Learning validation is not the neural network
alone. It is the complete training procedure under a stated data
boundary. `sciModelFlowR` 0.6.0 is organized to keep that procedure
inspectable.

#### 21.0.1 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.2 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.3 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.4 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.5 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.6 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.7 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.8 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.9 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.10 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.11 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.12 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.13 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.14 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.15 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.16 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.17 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.18 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.19 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.20 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.21 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.22 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.23 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.24 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.25 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.26 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.27 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.28 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.29 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.30 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.31 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.32 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.33 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.34 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.35 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.36 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.37 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.38 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.39 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.40 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.41 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.42 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.43 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.44 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.45 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.46 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.47 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.48 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.49 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.50 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.51 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.52 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.53 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.54 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.55 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.56 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.57 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.58 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.59 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.60 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.61 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.62 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.63 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.64 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.65 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.66 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

#### 21.0.67 Scientific interpretation note

CPU execution is the reference path for portability. GPU acceleration
changes throughput and sometimes numerical behavior, but it does not
change the estimand. A scientific report should therefore record the
device, backend version, precision policy, seed policy, and whether
deterministic behavior was requested or only best-effort. Repeated seeds
are useful when initialization sensitivity matters, but repeated seeds
are not substitutes for resampling across observational units.

#### 21.0.68 Scientific interpretation note

An architecture contract describes what shape of information a model
expects and what task it performs. It is deliberately separate from a
`torch` module. This permits the same scientific description to be
serialized, compared across languages, inspected without loading a GPU
framework, and used to reject an incompatible modality before expensive
training begins.

#### 21.0.69 Scientific interpretation note

Deep Learning should enter a scientific workflow because the data
structure or predictive target justifies representation learning, not
because a neural network is available. A network adds many degrees of
freedom: architecture, optimizer, learning-rate schedule, batch size,
stopping rule, random initialization, device behavior, and sometimes
nondeterministic kernels. `sciModelFlowR` therefore treats training
configuration as scientific provenance. The architecture and training
policy are explicit objects, and the fitted backend object is not the
public scientific result.

#### 21.0.70 Scientific interpretation note

The first distinction is between the **analysis data** used to fit
parameters and the **validation data** used to control optimization.
Early stopping makes repeated decisions from validation loss, so the
validation set is part of model development. A final test or external
validation set cannot be re-labelled as validation merely because a
training API accepts it. The package keeps that boundary visible because
optimistic performance estimates can otherwise arise before any formal
model comparison occurs.

### 21.1 Tensor training for sequences, spectra, and images

The tabular
[`smf_dl_train()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md)
interface is intentionally not used to flatten structured inputs.
Version 0.6.0 therefore provides
[`smf_dl_train_tensor()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md)
and
[`smf_dl_predict_tensor()`](https://wep69.github.io/sciModelFlowR/reference/deep-learning-060.md)
for N-dimensional arrays whose first dimension is the observation.
Recurrent and Transformer inputs use observation × sequence × feature
layout; CNN/TCN and image layouts must match the architecture’s declared
channel and spatial dimensions. The function validates this shape before
fitting. An explicit validation list may be supplied for
development-time early stopping, but a role of `final_test` or
`external_test` is rejected. This preserves the same information
boundary used throughout the package while giving structured neural
architectures an executable package-native path.
