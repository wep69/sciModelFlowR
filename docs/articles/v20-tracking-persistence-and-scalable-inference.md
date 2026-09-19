# Tracking, Persistence, Deployment, and Scalable Inference

## Tracking, persistence, deployment, and scalable inference

**Package:** `sciModelFlowR`\
**Release:** 0.8.0\
**Role:** focused scientific vignette 20

This vignette explains how a scientific modeling result becomes a
reproducible operational artifact without erasing the design,
preprocessing, uncertainty, and provenance decisions that made the
result scientifically interpretable. The 0.8.0 release does not redefine
`sciModelFlowR` as a generic MLOps platform. Instead, it adds a
conservative operational layer around the scientific contracts
established in versions 0.1.0 through 0.7.0.

The core rule is:

> **Track decisions, validate artifacts before loading them, preserve
> the complete inference path, and never treat deployment convenience as
> evidence of scientific validity.**

### 1. Learning objectives

After completing this vignette, the reader should be able to distinguish
experiment tracking from scientific validation, create a local run
tracker, resume an interrupted run without rewriting its identity, log
metrics and portable metadata, construct a checksum-verified inference
bundle, explain why opaque R serialization requires explicit trust,
verify schema compatibility before prediction, reproduce predictions
from a safe portable bundle, use resumable batch prediction, build a
data iterator, understand the boundaries of parallel inference, publish
a bundle through an optional pins board, use vetiver only when the
complete prediction semantics are preserved, and document deployment
limitations in a manuscript or operational report.

The instructional emphasis is intentionally conservative. A successful
deployment is evidence that software executed in a target environment.
It is not evidence that the model generalizes to a new population,
season, instrument, field, geographic region, or management regime.
Those claims require the validation design developed earlier in the
package.

### 2. Where version 0.8.0 fits in the package grammar

Versions 0.1.0 to 0.7.0 move from design declaration through model
fitting, uncertainty, diagnostics, and interpretation. Version 0.8.0
answers a different question: what must be preserved after the model has
been fitted so that another process can reproduce the same managed
inference path?

A minimal operational chain is:

``` text
scientific specification
        ↓
training-only preprocessing
        ↓
fitted feature state
        ↓
fitted model state
        ↓
labels and task semantics
        ↓
schema contract
        ↓
checksums and provenance
        ↓
validated inference bundle
        ↓
batch or service prediction
```

Every arrow is part of the scientific result. Saving only a backend
model object is therefore insufficient whenever prediction also depends
on centering, scaling, imputation, feature selection, encoding,
calibration, or class-label semantics.

### 3. Local tracking is the core path

The local tracker is deliberately dependency-light. It stores each run
in a directory under an experiment name and records immutable run
identity together with mutable run status. It can be used on a laptop,
teaching laboratory computer, network drive, or controlled research
workstation without an MLflow server.

``` r

tracker <- smf_tracker_local(
  path = "tracking",
  experiment = "nitrogen_response"
)

run <- smf_start_run(
  tracker,
  run_name = "baseline_stats",
  tags = list(site = "field_A", purpose = "teaching")
)

smf_log_metric(run, "rmse", 4.28)
smf_log_params(run, list(engine = "stats", model = "linear_regression"))
run <- smf_end_run(run, "finished")
```

The tracker records the history of computation. It does not decide
whether the split was appropriate, whether the model is calibrated, or
whether a domain shift invalidates the intended use. Those remain
scientific questions.

### 4. Resume semantics and run identity

Interrupted computational work should not silently become a new run. A
resumed run therefore keeps the same `run_id`. This matters when a later
audit needs to associate metrics, bundles, figures, or external tracker
records with one scientific computation.

``` r

run <- smf_start_run(tracker, run_name = "long_job")
run <- smf_end_run(run, "interrupted")

resumed <- smf_start_run(
  tracker,
  resume_run_id = run@run_id
)
```

The local implementation refuses to reopen a run already marked
`finished` as a mutable run. If a finished analysis must be repeated,
create a new run and retain the previous one. Reproducibility is
strengthened by preserving history, not by rewriting it.

### 5. Logging a complete sciModelFlowR result

When an `ExperimentResult` is available,
[`smf_log_result()`](https://wep69.github.io/sciModelFlowR/reference/tracking-persistence-080.md)
can log the package-native metrics, specification hash, data hash,
engine, package version, run manifest, and experiment specification.

``` r

smf_log_result(resumed, result)
resumed <- smf_end_run(resumed, "finished")
```

This is preferable to manually copying a single performance number. A
metric without its data hash, split semantics, preprocessing state, task
definition, and model specification is difficult to interpret later. In
scientific work, provenance is part of the result.

### 6. Optional MLflow tracking

MLflow integration is optional. The local tracker remains available when
the `mlflow` package or an MLflow server is absent.

``` r

if (requireNamespace("mlflow", quietly = TRUE)) {
  tracker_mlflow <- smf_tracker_mlflow(
    uri = "http://127.0.0.1:5000",
    experiment = "sciModelFlowR-demo"
  )
}
```

The adapter uses MLflow for run identity, parameters, metrics, and
artifacts, while `sciModelFlowR` keeps its own scientific objects. This
separation is deliberate: an external tracking system should not become
the authority for design semantics or uncertainty labels.

### 7. Why persistence needs a bundle rather than one R object

An inference bundle is a directory with explicit components. The exact
backend state may vary, but the bundle always exposes human-readable
metadata before any opaque state is loaded.

``` text
bundle/
├── manifest.json
├── spec.json
├── schema.json
├── preprocessing.json
├── features.json or features.rds
├── labels.json
├── run_manifest.json
├── model/
│   └── model_state.json or model.rds
├── checksums.sha256
└── README.md
```

The separation allows an auditor to inspect schema version, package
version, backend, source run, hashes, hardware record, and whether the
bundle is marked unsafe before loading a backend object.

### 8. Save a portable bundle

For supported [`stats::lm()`](https://rdrr.io/r/stats/lm.html) and
[`stats::glm()`](https://rdrr.io/r/stats/glm.html) workflows whose
post-preprocessing predictors can be represented safely, version 0.8.0
can store model coefficients and link semantics in JSON rather than an
opaque R serialization.

``` r

bundle_path <- tempfile("smf-bundle-")
smf_save_bundle(
  result,
  bundle_path,
  mode = "portable"
)
```

Portable export is intentionally narrow. The package does not label a
backend portable merely because
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) succeeds. Feature
representations that depend on opaque fitted objects, fitted probability
calibrators, and unsupported backend states force the workflow to use an
opaque bundle or fail if `portable_only` semantics are requested.

### 9. Validate before loading

Bundle validation precedes model loading.

``` r

validation <- smf_validate_bundle(bundle_path)
validation
```

The validator checks required files, SHA-256 values, and the major
bundle-schema version. A corrupted file is rejected before model state
is deserialized. This order is a security and reproducibility property,
not a convenience feature.

A major schema mismatch is also rejected with migration guidance. Minor
or patch evolution can be handled within the same major contract when
semantics remain compatible.

### 10. Explicit trust for opaque serialized state

R serialization is useful, but an arbitrary serialized object from an
untrusted source is not treated as a safe interchange format. Opaque
bundles therefore require explicit trust.

``` r

# Fails for an opaque bundle:
# smf_load_bundle(bundle_path)

trusted_bundle <- smf_load_bundle(
  bundle_path,
  trusted = TRUE
)
```

`trusted = TRUE` means the analyst accepts the origin of the serialized
state after checksum validation. It does not mean the statistical model
is trustworthy, unbiased, calibrated, or externally valid.

### 11. Portable loading without trust escalation

A portable bundle can be loaded without the unsafe deserialization path.

``` r

bundle <- smf_load_bundle(bundle_path)
```

The returned `InferenceBundle` contains the scientific task,
preprocessing state, feature state, model representation, input schema,
labels, manifest, and provenance. Prediction therefore uses the same
managed order as the original fit.

### 12. Schema checks before prediction

The bundle records required predictors and the training-time
preprocessing roles. Prediction fails when required columns are missing.
With strict schema checking, predictors declared numeric during fitting
must still arrive as numeric inputs.

``` r

pred <- smf_predict_bundle(
  bundle,
  new_data,
  strict_schema = TRUE
)
```

Schema checks are necessary but not sufficient. A numeric soil organic
carbon column measured in different units can pass a type check and
still be scientifically incompatible. Units, instrument version,
laboratory method, geographic support, and population definition belong
in the scientific validation record.

### 13. Prediction equivalence is an acceptance gate

A bundle should reproduce the managed prediction from the original
fitted result within a prespecified numerical tolerance.

``` r

p_live <- smf_predict(result, new_data)
p_bundle <- smf_predict_bundle(bundle, new_data)

stopifnot(isTRUE(all.equal(
  p_live,
  p_bundle,
  tolerance = 1e-12
)))
```

This is a Gold-style persistence test. It verifies the software
transformation from fitted workflow to stored artifact. It does not
replace external predictive validation.

### 14. Bundle metadata without loading model state

Operational systems often need to inspect an artifact before deciding
whether to load it.

``` r

info <- smf_bundle_info(bundle_path)
info$manifest
info$compatibility
info$unsafe_components
```

This allows a registry, review script, or deployment controller to
reject an artifact based on schema or provenance before any backend
model is instantiated.

### 15. Hardware-aware provenance

Version 0.8.0 extends the run manifest with hardware information.

``` r

smf_hardware_info()
```

The record includes operating-system information, logical and physical
cores, availability of GPU/CUDA when the optional `torch` stack is
usable, CUDA runtime version when available, and the `torch` package
version. GPU availability is not a reproducibility guarantee. Different
hardware and library versions can produce numerically different
floating-point paths, particularly for Deep Learning.

### 16. Deterministic batch planning

Large in-memory prediction tables should not require one monolithic
prediction call.
[`smf_chunk_plan()`](https://wep69.github.io/sciModelFlowR/reference/tracking-persistence-080.md)
creates deterministic row batches.

``` r

plan <- smf_chunk_plan(
  n = nrow(new_data),
  chunk_size = 1000
)
```

Rows are assigned in their original order. The final result reconstructs
that order. Deterministic chunking makes checkpoint recovery testable
and avoids accidental reordering of scientific identifiers.

### 17. Batch prediction

``` r

batch <- smf_batch_predict(
  bundle,
  new_data,
  batch_size = 1000
)

batch@prediction
```

The output records number of rows, number of batches, object hash,
input-data hash, worker count, and creation time. For classification,
probability columns remain explicit rather than being collapsed silently
to class labels.

### 18. Resumable batch prediction

Long prediction jobs can checkpoint each completed batch as a CSV file
with its own SHA-256 hash.

``` r

batch <- smf_batch_predict(
  bundle,
  new_data,
  batch_size = 5000,
  checkpoint_dir = "prediction-checkpoint"
)

resumed <- smf_batch_predict(
  bundle,
  new_data,
  batch_size = 5000,
  checkpoint_dir = "prediction-checkpoint",
  resume = TRUE
)
```

Resume is accepted only when input hash, object hash, row count, and
batch size match the original job. Each existing batch is
checksum-verified before reuse. This prevents a partially modified
checkpoint directory from being mistaken for valid completed work.

### 19. Iterator interface

For instructional and custom streaming workflows, a resettable iterator
exposes a small next/reset contract.

``` r

it <- smf_data_iterator(new_data, chunk_size = 250)

repeat {
  chunk <- smf_iterator_next(it)
  if (is.null(chunk)) break
  # process chunk
}

smf_iterator_reset(it)
```

The core iterator accepts a data frame. Database, Arrow, DuckDB, raster,
cloud-object, or instrument-stream adapters can implement equivalent
chunk semantics externally. Version 0.8.0 does not pretend that a
data-frame iterator solves out-of-core computing in every scientific
domain.

### 20. Mapping over chunks

``` r

pieces <- smf_map_iterator(
  it,
  function(chunk) summary(chunk)
)
```

This interface is useful for quality-control summaries, unit checks,
monitoring, or pre-deployment inspection. When the transformation learns
parameters from data, however, the earlier training-boundary rules still
apply. Streaming does not authorize fitting preprocessing on future
assessment observations.

### 21. Parallel batch execution

[`smf_batch_predict()`](https://wep69.github.io/sciModelFlowR/reference/tracking-persistence-080.md)
accepts more than one worker. The implementation uses R’s process-based
parallel infrastructure and reconstructs results in deterministic batch
order.

``` r

parallel_pred <- smf_batch_predict(
  bundle,
  new_data,
  batch_size = 2000,
  workers = 2
)
```

Parallel execution can increase memory use because workers may receive
copies of model state and batch data. GPU backends may require a
different concurrency strategy. More workers therefore do not imply
better throughput. Benchmark the intended hardware and record the
configuration.

### 22. Publish bundles with pins

The optional `pins` adapter uploads an already validated bundle archive
to a configured board.

``` r

if (requireNamespace("pins", quietly = TRUE)) {
  board <- pins::board_folder("model-board", versioned = TRUE)
  smf_pins_publish_bundle(
    board,
    bundle_path,
    name = "yield_model"
  )
}
```

Versioning is controlled by the board. A pin is a distribution
mechanism, not a replacement for the bundle’s internal SHA-256 manifest.

### 23. Vetiver interoperability with a scientific guard

Vetiver can store and deploy trained R models, but a generic backend
model does not automatically include `sciModelFlowR` preprocessing and
feature semantics. The 0.8.0 adapter therefore permits the generic
vetiver path only when preprocessing is identity, all managed predictors
are already numeric, no learned feature transformation is present, and
no probability calibrator must be replayed.

``` r

if (requireNamespace("vetiver", quietly = TRUE)) {
  v <- smf_vetiver_model(
    result,
    model_name = "yield_model",
    prototype_data = prototype
  )
}
```

For a nontrivial managed pipeline, use the `sciModelFlowR` inference
bundle rather than dropping preprocessing to make deployment easier.

### 24. Generate a Plumber endpoint file

A bundle can be wrapped in a minimal Plumber prediction endpoint.

``` r

smf_write_plumber(
  bundle_path,
  file = "plumber.R"
)
```

The generated file loads the bundle and calls
[`smf_predict_bundle()`](https://wep69.github.io/sciModelFlowR/reference/tracking-persistence-080.md).
An opaque bundle still requires explicit trust. Production API
hardening, authentication, rate limits, observability, container
security, and network controls remain responsibilities of the deployment
environment.

### 25. ONNX is not assumed to be equivalent

The package does not claim universal ONNX export. Preprocessing, custom
distributions, calibration, probabilistic heads, and unsupported
operators can alter semantics across runtimes.
[`smf_export_onnx()`](https://wep69.github.io/sciModelFlowR/reference/tracking-persistence-080.md)
therefore requires an explicit exporter callback and returns a warning
that numerical equivalence must be independently tested.

A successful file conversion is not enough. A deployment validation
should compare original and exported predictions across Gold, boundary,
missing-value, categorical-level, and scientifically realistic cases.

### 26. What the bundle does not prove

A valid checksum proves byte integrity relative to the bundle’s checksum
manifest. A compatible schema proves the reader understands the declared
major bundle format. A successful prediction proves the execution path
produced an output. None of these establish transportability to a new
domain.

For agronomic use, separately ask whether cultivar, soil class,
management, sensor, weather regime, sampling support, and measurement
protocol match the intended use. For spectroscopy, ask whether
instrument, wavelength grid, preprocessing and reference laboratory
method match. For spatial models, ask whether the new prediction domain
lies within the support of the training locations and covariates.

### 27. Security model

The security model has four layers. First, checksums are verified before
loading model state. Second, major schema compatibility is checked
before interpretation. Third, opaque serialization requires explicit
trust. Fourth, portable metadata remain inspectable without
deserializing backend objects.

This model reduces accidental unsafe loading but is not a sandbox. If an
artifact comes from an untrusted source, the safest action is not to
load it. Hashes verify integrity relative to a manifest; they do not
establish who created the manifest.

### 28. Scientific review of a deployment candidate

Before promoting an artifact, review the scientific question, target and
units, experimental or sampling design, split geometry, external
validation domain, preprocessing boundaries, tuning procedure,
uncertainty method, calibration, explanation limitations, training data
provenance, bundle schema, backend version, and deployment input schema.

A deployment review should also define what conditions trigger
retraining or withdrawal. Examples include new sensor hardware, changed
laboratory assay, cultivar turnover, geographic expansion, new soil
mapping support, substantial covariate shift, failure of interval
coverage, or persistent calibration deterioration.

### 29. Monitoring is not automatic causality

Operational monitoring can reveal that an input distribution or model
performance changed. It cannot by itself identify why. A change in
residual distribution after deployment may reflect climate, management,
measurement, population composition, data pipeline defects, or
biological change. Treat monitoring as evidence that deserves
investigation, not as a causal diagnosis.

### 30. Reproducible reporting

A deployment-oriented methods section should report the package version,
bundle schema version, source run ID, model/backend version,
preprocessing and feature state, input schema, checksum policy, trust
policy, hardware record, batch strategy, and validation design used to
justify intended use.

For an opaque bundle, explicitly state that backend state requires
trusted loading. For an exported runtime such as ONNX, state the
numerical comparison procedure used to establish equivalence. For a
Plumber or vetiver API, report the pinned/model version rather than
merely saying that an API was deployed.

### 31. Complete local example

``` r

library(sciModelFlowR)

d <- smf_load_dataset("gold_linear_regression")

spec <- smf_experiment_spec(
  task = smf_task_spec("regression", "yield"),
  data = smf_data_spec(
    "yield",
    c("nitrogen", "rainfall", "soil_n"),
    id_column = "obs_id"
  ),
  design = smf_design_spec(id_column = "obs_id"),
  preprocessing = smf_preprocess_spec(
    "median",
    center = TRUE,
    scale = TRUE
  ),
  resampling = smf_resampling_spec(
    "holdout",
    train_prop = 0.8,
    seed = 260915L
  ),
  model = smf_model_spec(
    "linear_regression",
    "stats"
  ),
  metrics = list(smf_metric_spec("rmse")),
  tracking = smf_tracking_spec("none"),
  persistence = smf_persistence_spec(),
  deployment = smf_deployment_spec("local"),
  scalability = smf_scalability_spec(chunk_size = 25L)
)

result <- smf_fit_experiment(spec, d)

tracker <- smf_tracker_local(tempfile("tracker-"), "gold-demo")
run <- smf_start_run(tracker, run_name = "gold-linear")
smf_log_result(run, result)
run <- smf_end_run(run, "finished")

bundle_dir <- tempfile("bundle-")
smf_save_bundle(result, bundle_dir, mode = "portable")
smf_validate_bundle(bundle_dir)
bundle <- smf_load_bundle(bundle_dir)

single <- smf_predict_bundle(bundle, d[1:10, ])
batched <- smf_batch_predict(bundle, d[1:10, ], batch_size = 3L)

stopifnot(isTRUE(all.equal(
  as.numeric(single),
  batched@prediction$.prediction,
  tolerance = 1e-12
)))
```

The example is intentionally small. The scientific value is not the size
of the dataset. It is that the same design-aware fitted workflow is
traceable, bundled, verified, reloaded, and predicted without silently
changing its semantics.

### 32. Common mistakes

**Saving only the backend model.** This can omit preprocessing, feature
selection, class labels, or calibration.

**Using a checksum as proof of scientific validity.** A checksum detects
altered bytes, not biased sampling or domain shift.

**Loading opaque artifacts from unknown sources.** Use explicit trust
only for artifacts whose provenance is established.

**Deploying a vetiver model after dropping preprocessing.** The deployed
object must represent the same inference function that was validated.

**Using the final test set as a monitoring threshold-tuning set.** The
final test remains evaluation evidence, not a source of adaptive tuning
decisions.

**Changing batch size and reusing an old checkpoint without
validation.** Resume metadata must match the current computation.

**Assuming more parallel workers always improve performance.** Measure
throughput and memory on the actual target hardware.

**Treating an ONNX conversion as numerical certification.** Compare
predictions explicitly under a prespecified tolerance.

### 33. Minimum release checklist for an inference artifact

source scientific question and intended use are documented;

package and bundle schema versions are recorded;

source run ID and specification hash are recorded;

data and split hashes are retained where allowed;

input schema and labels are explicit;

preprocessing state is included;

learned feature state is included or explicitly absent;

calibration state is included when needed;

checksums validate before loading;

opaque state is marked unsafe;

`trusted = TRUE` is never supplied automatically;

original and reloaded predictions agree within tolerance;

intended hardware/backend versions are recorded;

batch-resume behavior has been tested when used;

external adapters preserve the complete inference semantics;

final scientific validation is separate from artifact validation.

### 34. Interpretation for peer review

A reviewer evaluating a computational manuscript can use the 0.8.0
artifacts to separate three questions. First, can the model artifact be
reconstructed and executed? Second, does the artifact reproduce the
reported computation? Third, does the study design justify the
scientific claim? Tracking and persistence primarily strengthen the
first two. The third still depends on sampling, design, resampling,
uncertainty, and external validation.

A strong manuscript should therefore not use phrases such as “the model
was validated because it was successfully deployed.” Deployment is an
engineering outcome. Validation is a scientific assessment against an
appropriately defined target population or process.

### 35. Final perspective

The operational layer of `sciModelFlowR` is intentionally narrower than
a general production platform. Its purpose is to preserve the scientific
workflow while the fitted result moves across sessions, computers, batch
jobs, registries, and deployment tools.

The recommended sequence is:

**fit under design-aware safeguards → record provenance → validate
bundle → load safely → verify prediction equivalence → deploy only
compatible semantics → monitor without causal overclaiming → retain the
original scientific validation boundaries.**

That sequence keeps tracking and deployment subordinate to the
scientific model rather than allowing infrastructure to redefine what
the analysis means.

## Appendix A. Operational scenarios

#### A.1 Agronomic field trial

A field-trial model may be statistically well fitted and still be
inappropriate for a neighboring farm if soil, cultivar, planting date,
management, or weather support differs. The bundle should preserve
exactly how the original predictors were transformed. A new farm should
be treated as a new domain, and the deployment report should state
whether any independent farms were retained for external validation.
Batch prediction over a field grid is an execution strategy; it is not a
substitute for spatially appropriate validation.

#### A.2 Soil spectroscopy

Spectroscopic deployment is especially sensitive to instrument and
preprocessing identity. A bundle can preserve the fitted numerical
transformation, but it cannot guarantee that a new spectrometer has the
same wavelength registration, spectral resolution, detector response,
calibration transfer, or reference-laboratory distribution. Instrument
identifiers and preprocessing provenance should therefore accompany the
bundle registry. When an instrument changes, independent transfer
validation is preferable to silently appending new spectra to the
training distribution.

#### A.3 Environmental time series

For time-series prediction, a bundle can reproduce the fitted model and
preprocessing but cannot freeze future temporal dependence. Monitoring
should preserve timestamps and evaluate whether residual structure
changes. Retraining rules must avoid using future test periods as
repeated tuning data. A rolling production system should define
prospective evaluation windows separately from model-update windows.

#### A.4 Image and Deep Learning pipelines

Neural models frequently contain large opaque backend state. Version
0.8.0 therefore treats those states as requiring explicit trust unless a
certified portable representation is available. Hardware and CUDA
versions should be preserved because kernels, precision modes, and
device libraries can alter numerical paths. Checkpoint hashes establish
identity of the weight artifact but do not prove equivalence after
conversion to another runtime.

#### A.5 Bayesian and probabilistic models

A point-prediction service can accidentally discard posterior or
distributional semantics. If downstream decisions require credible
intervals, posterior predictive draws, quantiles, or conformal
intervals, deployment must preserve those outputs and their labels. A
credible interval must not be relabeled as a conformal interval simply
because both have lower and upper endpoints. Operational serialization
must retain the uncertainty descriptor developed in version 0.7.0.

## Appendix B. Failure-oriented validation cases

A useful persistence test suite does not contain only successful round
trips. Deliberately corrupt one bundle file and verify rejection. Change
the major schema version and verify migration guidance. Remove a
required predictor and verify schema failure. Change a numeric predictor
to character and verify a strict type failure. Create an opaque bundle
and verify that loading without trust fails. Change one checkpoint batch
and verify checksum failure. Attempt resume with a different dataset or
batch size and verify that the job is rejected rather than merged with
stale outputs.

These tests are valuable because persistence errors can produce
plausible-looking predictions. Silent plausibility is more dangerous
than an explicit error. The package therefore favors hard failures at
boundaries where inference semantics cannot be verified.

## Appendix C. Reproducibility versus repeatability versus portability

**Repeatability** asks whether the same code and environment can
reproduce the computation. **Reproducibility** in practical scientific
software often extends this to recorded data, specification, versions,
seeds, and analysis decisions. **Portability** asks whether an artifact
can be executed in another compatible environment. These concepts
overlap but are not identical.

A portable JSON coefficient representation may improve portability
without changing the evidence for external validity. Conversely, an
externally validated model may still be difficult to reproduce if the
fitted preprocessing state was not recorded. The 0.8.0 architecture
therefore treats operational provenance and scientific validation as
complementary requirements.

## Appendix D. Suggested local validation sequence

1.  Install the package and core dependencies in a clean R library.
2.  Run the 0.1.0 through 0.7.0 regression suite first.
3.  Execute the local-tracker tests on a writable local directory.
4.  Fit the frozen linear Gold workflow and save a portable bundle.
5.  Validate every checksum and compare live versus reloaded
    predictions.
6.  Save the same result as an opaque bundle and verify trust
    enforcement.
7.  Corrupt one copied bundle file and confirm failure before loading.
8.  Execute batch prediction with multiple chunk sizes and verify
    identical row order.
9.  Interrupt a checkpointed batch job and resume it.
10. Run the same batch workflow with one and multiple workers where
    supported.
11. Test optional MLflow only in an environment with a deliberately
    configured tracking URI.
12. Test pins with a temporary versioned folder board before any remote
    board.
13. Test vetiver only on a workflow that satisfies the
    identity-preprocessing guard.
14. Generate a Plumber file and test its endpoint in an isolated local
    process.
15. Record CPU/GPU/CUDA metadata and compare it with the actual host.
16. Only after these checks proceed to `R CMD check --as-cran` and the
    broader release matrix.

## Appendix E. Reporting language

Appropriate language includes: “The fitted workflow was stored in a
checksum-verified inference bundle; the reloaded bundle reproduced
held-out predictions within the prespecified numerical tolerance.” This
describes what was tested.

Avoid: “The bundle proves the model is valid.” Artifact integrity does
not establish scientific validity.

Appropriate language includes: “Opaque backend state was loaded only
from a trusted project artifact after checksum validation.” This makes
the trust assumption explicit.

Avoid: “RDS is safe because it is an R format.” Serialization is not
treated as a trust boundary.

Appropriate language includes: “Batch inference preserved row order and
was restartable from checksum-verified checkpoints.” This is an
operational property.

Avoid: “Parallel prediction increased model accuracy.” Parallel
execution should not alter the statistical target or predictive result
beyond numerical tolerance.

## Appendix F. Questions for an operational audit

#### F.1

Can an independent analyst identify the exact source run from the
deployed artifact, and can that run be connected to the scientific
specification rather than only to a backend model file? A satisfactory
answer should cite an artifact, manifest field, validation test, or
explicit limitation. Operational confidence should be based on
inspectable evidence rather than on the fact that a prediction endpoint
returned HTTP success.

#### F.2

Does the artifact preserve every learned transformation required before
model prediction, including imputation, centering, scaling, categorical
encoding, feature selection, representation learning, and calibration
when applicable? A satisfactory answer should cite an artifact, manifest
field, validation test, or explicit limitation. Operational confidence
should be based on inspectable evidence rather than on the fact that a
prediction endpoint returned HTTP success.

#### F.3

Can the system inspect bundle metadata and checksum status before
loading any opaque model state, and is unsafe loading impossible without
an explicit trust decision? A satisfactory answer should cite an
artifact, manifest field, validation test, or explicit limitation.
Operational confidence should be based on inspectable evidence rather
than on the fact that a prediction endpoint returned HTTP success.

#### F.4

Does the schema describe the predictors actually required at inference
time, and are scientific units, domains, and measurement protocols
documented outside the minimal machine-readable type contract? A
satisfactory answer should cite an artifact, manifest field, validation
test, or explicit limitation. Operational confidence should be based on
inspectable evidence rather than on the fact that a prediction endpoint
returned HTTP success.

#### F.5

Has prediction equivalence been tested on ordinary observations,
boundary cases, missing-value patterns allowed by the preprocessing
contract, and discrepant cases likely to expose implementation
differences? A satisfactory answer should cite an artifact, manifest
field, validation test, or explicit limitation. Operational confidence
should be based on inspectable evidence rather than on the fact that a
prediction endpoint returned HTTP success.

#### F.6

If a tracker service is unavailable, can the scientific analysis still
run and preserve local provenance without silently dropping the
experiment record? A satisfactory answer should cite an artifact,
manifest field, validation test, or explicit limitation. Operational
confidence should be based on inspectable evidence rather than on the
fact that a prediction endpoint returned HTTP success.

#### F.7

If batch inference is interrupted, can it resume only when the input
data and model identity match, rather than concatenating stale results
from a different computation? A satisfactory answer should cite an
artifact, manifest field, validation test, or explicit limitation.
Operational confidence should be based on inspectable evidence rather
than on the fact that a prediction endpoint returned HTTP success.

#### F.8

If an external deployment framework is used, is the complete inference
function preserved, or has part of the preprocessing/calibration path
been omitted because the framework expects a simpler model object? A
satisfactory answer should cite an artifact, manifest field, validation
test, or explicit limitation. Operational confidence should be based on
inspectable evidence rather than on the fact that a prediction endpoint
returned HTTP success.

#### F.9

Are hardware and backend versions recorded sufficiently to interpret
numerical differences across CPU, GPU, CUDA, and Deep Learning
environments? A satisfactory answer should cite an artifact, manifest
field, validation test, or explicit limitation. Operational confidence
should be based on inspectable evidence rather than on the fact that a
prediction endpoint returned HTTP success.

#### F.10

Is there a documented migration plan for future bundle-schema major
versions, including a rule that incompatible major schemas fail rather
than being guessed into compatibility? A satisfactory answer should cite
an artifact, manifest field, validation test, or explicit limitation.
Operational confidence should be based on inspectable evidence rather
than on the fact that a prediction endpoint returned HTTP success.

## Appendix G. Detailed verification matrix

A persistence layer should be validated against several distinct failure
classes because a single successful reload exercises only the easiest
path. The first class is **identity failure**. Change the source run
identifier, specification hash, or bundle manifest and verify that the
resulting artifact is distinguishable from the original. This does not
necessarily make the bundle unusable, but it must prevent two
scientifically different artifacts from being treated as the same
registered model.

The second class is **integrity failure**. Copy a valid bundle, modify
one byte in `schema.json`, `preprocessing.json`, or the model-state
file, and verify that checksum validation fails before any prediction
occurs. Repeat the test for a batch checkpoint CSV. Integrity failures
should identify the affected file so the analyst can distinguish
corruption from a schema problem or backend-version problem.

The third class is **compatibility failure**. Modify a copied manifest
to a hypothetical bundle schema `2.0.0`. A 1.x reader should refuse to
guess how a 2.x object should be interpreted and should request an
explicit migration. Scientific software benefits from conservative
schema handling because a superficially similar field can acquire
different semantics across major versions.

The fourth class is **input-schema failure**. Remove a required
predictor, change a numeric predictor to character, or rename a
predictor. The deployment path should fail before model evaluation. Then
test a scientifically incompatible value that still has the correct R
type, such as rainfall supplied in inches when the training contract
assumed millimeters. The first failure should be caught automatically;
the second illustrates why machine-readable schema checks must be
supplemented by domain metadata and scientific review.

The fifth class is **pipeline omission**. Compare a managed bundle
prediction with a prediction obtained from the raw backend object while
intentionally omitting scaling or feature selection. The difference
demonstrates why backend-only deployment is unsafe for nontrivial
workflows. This exercise is particularly valuable in teaching because it
shows that model coefficients or weights are only one component of the
inference function.

The sixth class is **trust-boundary failure**. Save a workflow in opaque
mode and verify that checksum validation can inspect the artifact while
loading remains blocked. Only an explicit `trusted = TRUE` decision
should cross the serialization boundary. The test should also confirm
that a portable safe-state bundle does not require this escalation.

The seventh class is **resume mismatch**. Produce a checkpointed batch
prediction, then attempt to resume with one row changed, a different
model bundle, or a different batch size. All three should fail. Resume
is a continuation of one computation, not a mechanism for merging
outputs from computations that happen to share a directory.

The eighth class is **ordering failure**. Use an input with a stable row
identifier, predict in small batches, and verify that the reconstructed
output aligns exactly with the original row order. Repeat with parallel
workers. If downstream decisions depend on plot, plant, sample,
spectrum, patient, or location identifiers, ordering errors can be
scientifically serious even when individual prediction values are
numerically correct.

The ninth class is **optional-service failure**. Uninstall or disconnect
MLflow and verify that local fitting and local tracking remain
available. Disconnect a remote pins board and verify that the local
bundle remains intact. Optional integrations should extend portability,
not become hidden requirements for reproducing the scientific analysis.

The tenth class is **deployment-framework mismatch**. Attempt to create
a generic vetiver object from a result with nonidentity preprocessing.
The package should refuse rather than export only the backend model.
This hard failure is intentional: losing preprocessing to gain
deployment convenience changes the function being deployed.

## Appendix H. Architecture decisions for maintainers

The local tracker is intentionally implemented with ordinary files and
JSON rather than a database. This keeps the core dependency surface
small, makes runs inspectable with standard tools, and provides a
reference behavior against which remote trackers can be compared. It is
not designed to replace a transactional experiment-tracking server under
heavy concurrent writes. If concurrent multi-process tracking becomes a
requirement, it should be introduced as a separate backend with explicit
locking and failure semantics.

The inference bundle separates portable metadata from backend state.
This makes it possible to inspect the scientific specification and
schema even when the fitted engine is unavailable. It also makes the
security boundary visible. A future backend-specific safe exporter can
be added without changing the top-level bundle contract, provided it
records its storage type and compatibility information in the manifest.

Portable `stats` export in 0.8.0 is deliberately limited to models whose
post-preprocessing design can be represented by named numerical
predictors and coefficients. This is a scientific engineering decision
rather than a limitation to be hidden. Supporting arbitrary factor
contrasts, splines, custom transformations, offsets, and interaction
terms requires a richer portable design-matrix contract. Those
capabilities should be added only with differential tests against
[`predict.lm()`](https://rdrr.io/r/stats/predict.lm.html) or
[`predict.glm()`](https://rdrr.io/r/stats/predict.glm.html) across
discrepant cases.

The current iterator is also intentionally modest. It defines the
semantics of chunk progression and reset without claiming out-of-core
support for every storage system. Future Arrow, DuckDB, database,
raster, or cloud adapters should implement the same conceptual contract
while avoiding materialization of the complete dataset. Their tests must
include deterministic row identity and recovery after partial failure.

Parallel batch prediction uses process-based R parallelism because it is
widely available. This does not mean every backend should use multiple R
workers. A GPU-resident neural model may perform better with one model
process and internal device batching. A large Bayesian posterior object
may be expensive to copy to multiple workers. The package therefore
records worker configuration but leaves hardware-specific performance
benchmarking to the validation environment.

## Appendix I. Scientific communication examples

For a methods section, a precise statement could be: “The fitted
workflow was persisted with sciModelFlowR 0.8.0 as a bundle containing
the experiment specification, training-derived preprocessing state,
model state, input schema, labels, source-run manifest, and SHA-256
checksums. Bundle integrity and schema compatibility were verified
before loading. Reloaded predictions were compared with predictions from
the in-memory fitted workflow using a prespecified numerical tolerance.”

For an opaque backend, add: “Because the backend required R-native
serialized state, loading was restricted to trusted project artifacts
and required explicit trust after checksum verification.” This statement
tells the reader what security assumption remains.

For scalable prediction, report: “Predictions were generated in
deterministic row batches with preserved input order. Interrupted jobs
were resumed only when the model identity, input-data hash, row count,
and batch size matched the original checkpoint manifest.” This is more
informative than simply stating that prediction was parallelized.

For optional tracking, report both layers: “Scientific specifications
and manifests were maintained by sciModelFlowR; run metrics and
artifacts were additionally mirrored to MLflow.” This avoids implying
that the external service defines the statistical semantics of the
analysis.

For external model registries, report the exact version or content hash.
A statement such as “the latest model was deployed” is not reproducible
because “latest” changes over time. The deployed artifact should be
linked to a frozen bundle version, source run, and checksum.

## Appendix J. Transition to version 0.9.0

Version 0.8.0 provides the operational substrate needed for the
integrated release candidate. Version 0.9.0 can now build domain
workflows without inventing separate persistence or tracking logic for
agronomy, soils, spectroscopy, spatial/environmental analysis, or
external validation. Each domain workflow should produce the same
package-native result, manifest, tracking record, and inference bundle
when appropriate.

The central requirement for that transition is that domain convenience
functions do not weaken the contracts established here. A spectroscopy
workflow must not bypass instrument-domain validation merely because a
bundle can be deployed. A spatial workflow must not randomize held-out
locations merely because batch prediction is efficient. An agronomic
workflow must not infer experimental independence from a deployment
table. Operational maturity should make scientific assumptions more
visible, not less visible.

The 0.9.0 integration tests should therefore reuse 0.8.0 bundles and
tracking records while adding cross-module scientific scenarios.
External validation results should be loggable as separate evidence
rather than being merged into tuning history. Domain reports should
distinguish the model-development domain, calibration domain, conformal
calibration domain when used, final internal test domain, and truly
external validation domain.

Finally, the 0.8.0 bundle schema should remain stable through the 0.9.0
release candidate unless a demonstrated semantic defect requires a
migration. Stability here is important because domain workflows will
begin to depend on the persistence format. Any migration must be
explicit, versioned, checksum-preserving where possible, and validated
against frozen inference fixtures.
