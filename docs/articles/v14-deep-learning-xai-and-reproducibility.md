# Deep Learning Explainability, Checkpoints, and Reproducible Scientific Reporting

**Package:** `sciModelFlowR`\
**Version targeted:** `0.6.0`\
**Status:** source-complete; runtime validation deferred to the
consolidated local validation cycle.

> The code blocks are designed for local execution after optional Deep
> Learning backends are installed. The package does not require `torch`,
> `luz`, or `keras3` merely to load the core scientific workflow.

## 1 1. Explain a network without claiming a mechanism

Gradient explanations are model diagnostics and descriptive
attributions. They do not convert observational prediction into causal
inference.

## 2 2. Learning objectives

The reader should be able to compute saliency, gradient-times-input and
Integrated Gradients; specify a baseline; use the explicit Grad-CAM
activation contract; compare gradient explanations with model-agnostic
XAI; audit checkpoints; and report device/reproducibility information.

## 3 3. Saliency

``` r

# sal <- smf_dl_saliency(
#   fit,
#   new_data = d[1:10, ],
#   target_output = 1
# )
```

Saliency measures local derivative sensitivity. It can become small in
saturated regions even when the feature was important to the fitted
representation.

## 4 4. Gradient times input

``` r

# gx <- smf_dl_gradient_x_input(
#   fit,
#   d[1:10, ],
#   target_output = 1
# )
```

Multiplying by the input changes the scale and reference interpretation.

## 5 5. Integrated Gradients

``` r

# ig <- smf_dl_integrated_gradients(
#   fit,
#   d[1:10, ],
#   baseline = rep(0, 6),
#   target_output = 1,
#   steps = 100
# )
```

The baseline is part of the estimand.

## 6 6. Choosing a baseline

Possible baselines include:

- physically meaningful absence/reference state;
- training-set mean on a standardized scale;
- low-information image;
- domain-specific background spectrum.

Do not use zero merely because it is convenient when zero has no
scientific meaning.

## 7 7. Completeness checks

Integrated Gradients has a completeness property under its assumptions.
The 0.6.0 local validation suite should test whether summed attributions
approximately reproduce the difference between model output at the
observation and baseline.

## 8 8. Grad-CAM

``` r

# cam <- smf_dl_gradcam(
#   fit,
#   input = image_tensor,
#   activation_fn = function(model, x) {
#     # Return the chosen convolutional activations explicitly.
#     list(output = output, activations = activations)
#   },
#   target_output = 2
# )
```

The explicit callback prevents the package from guessing a
scientifically meaningful convolutional layer.

## 9 9. Compare gradient and model-agnostic explanations

Permutation importance from 0.5.0 asks what happens to predictive
performance when a feature is disrupted. Integrated Gradients asks how
the output changes along a path in input space. Agreement is
informative, disagreement is also informative.

## 10 10. Explanation stability across seeds

A network may attain similar prediction performance from different
internal representations. Repeat explanations across independent seeds
and outer folds.

## 11 11. Explanation stability across architectures

If MLP, CNN and Transformer models have similar generalization but
emphasize different variables, the scientific conclusion should
acknowledge representational non-uniqueness.

## 12 12. Spatial heat maps

For image data, explanation maps should be shown with the original
image, scale and region of interest. Smoothing or resizing must be
reported.

## 13 13. Spectral explanations

For spectra, align attributions to physical wavelength or wavenumber
axes after any resampling. Do not interpret transformed component
indices as wavelengths.

## 14 14. Sequence explanations

For recurrent or attention models, preserve time ordering. An
attribution at one time point may depend on previous context.

## 15 15. Checkpoint provenance

``` r

fit@checkpoint
```

The recorded object includes:

- file path;
- SHA-256;
- architecture hash;
- training-spec hash;
- epoch;
- safe metadata;
- backend identity.

## 16 16. Safe loading

``` r

# smf_dl_load_checkpoint(fit@checkpoint, fit@architecture)
# -> blocked

# smf_dl_load_checkpoint(
#   fit@checkpoint,
#   fit@architecture,
#   trusted = TRUE
# )
```

Opaque backend serialization is not treated as a safe interchange
format.

## 17 17. Resume versus reproducibility

Resuming a checkpoint continues an optimization trajectory. Reproducing
an analysis means reconstructing the whole declared workflow from data,
split manifests, specs, package versions and seeds.

## 18 18. Backend versions

Deep Learning reproducibility is unusually sensitive to backend
versions. Capture `torch`, LibTorch/CUDA runtime where applicable, `luz`
or `keras3`, operating system, device and precision.

## 19 19. GPU tolerance

GPU validation should use numerical tolerances appropriate to the
calculation. Bitwise equality is not a sensible universal gate across
hardware.

## 20 20. CPU reference suite

The package’s CPU smoke suite should remain lightweight enough to run
without CUDA. It validates construction, one short fit, prediction,
checkpoint round-trip and gradient attribution.

## 21 21. External test protection

XAI stability calculated repeatedly on the final external test set can
itself become a development activity. Use resampled development
assessments for method selection; reserve external data for final
confirmation.

## 22 22. Publication figures

A good explanation figure should state:

- model and architecture;
- target output;
- explanation method;
- baseline or background;
- whether absolute values were used;
- aggregation across observations;
- stability or uncertainty summary;
- non-causal interpretation.

## 23 23. Explanation as sensitivity analysis

When correlated features can substitute for one another, attribution can
move between variables without large changes in predictions. Report
correlated-feature diagnostics from 0.5.0 together with gradient XAI.

## 24 24. Audit trail

A complete audit trail connects the final figure to:

``` text
data hash
-> split manifest
-> preprocessing spec
-> architecture hash
-> training spec hash
-> checkpoint hash
-> prediction target
-> explanation method
-> baseline/background
-> aggregation rule
```

## 25 25. Common mistakes

- reporting a heat map without the target class;
- hiding the baseline used for Integrated Gradients;
- interpreting attention or gradient magnitude as causal effect;
- loading an untrusted checkpoint;
- comparing explanations from differently preprocessed models;
- selecting the explanation method after inspecting external test
  results.

## 26 26. Reproducibility report template

A concise methods paragraph should state the network architecture,
optimizer and schedule, validation policy, checkpoint criterion,
device/precision, seeds, outer resampling, probabilistic method if used,
explanation method and baseline, software versions and whether final
external data were touched during development.

## 27 27. Connection to 0.5.0

The new gradient methods complement, rather than replace, permutation
importance, PDP, ICE, ALE and explanation-stability functions.
Neural-specific explanations remain embedded in the same non-causal
scientific contract.

## 28 28. Final perspective

A neural explanation is strongest when it is reproducible across
defensible runs, tied to the prediction target and accompanied by a
clear statement of what it does not identify.

#### 28.0.1 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.2 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.3 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.4 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.5 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.6 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.7 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.8 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.9 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.10 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.11 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.12 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.13 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.14 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.15 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.16 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.17 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.18 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.19 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.20 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.21 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.22 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.23 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.24 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.25 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.26 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.27 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.28 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.29 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.30 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.31 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.32 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.33 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.34 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.35 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.36 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.37 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.38 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.39 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.40 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.41 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.42 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.43 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.44 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.45 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.46 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.47 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.48 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.49 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.50 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.51 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.52 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.53 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.54 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.55 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.56 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.57 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.58 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.59 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.60 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.61 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.62 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.63 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.64 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.65 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.66 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.67 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.68 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.69 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.70 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.71 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.72 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.73 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.74 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.75 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.76 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.77 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.

#### 28.0.78 Scientific interpretation note

Integrated Gradients is most useful when the baseline has a defensible
interpretation. A zero vector may be computationally convenient but
scientifically nonsensical for standardized physiological or spectral
measurements. The package stores the baseline in the result so that a
figure cannot be separated from the reference state that generated the
attribution.

#### 28.0.79 Scientific interpretation note

Grad-CAM is offered through an explicit activation callback. The package
does not rely on hidden backend hooks to guess which convolutional layer
represents the scientific feature map. The analyst identifies the
activation tensor and target output. This is slightly more verbose, but
it makes the layer choice part of the analysis record and can be audited
when a publication figure is reviewed.

#### 28.0.80 Scientific interpretation note

Attribution stability should be examined alongside predictive stability.
Two networks can have similar test performance yet different saliency
maps because multiple representations explain the same training data.
The explanation-stability tools introduced in 0.5.0 remain relevant:
compare rankings or spatial summaries across folds, seeds and defensible
architectures instead of treating one visually attractive heat map as a
unique mechanistic explanation.

#### 28.0.81 Scientific interpretation note

Gradient-based explanation describes local sensitivity of a fitted
differentiable model. It does not establish causality. Saliency uses
derivatives of an output with respect to input features;
gradient-times-input weights those derivatives by the observed input;
Integrated Gradients averages gradients along a path from a declared
baseline. Each method therefore depends on scale, model saturation, the
chosen output and, for path methods, the baseline.
