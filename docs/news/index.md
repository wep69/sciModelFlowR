# Changelog

## sciModelFlowR 1.0.2

### Patch release - audited-tutorial corrections

Version 1.0.2 fixes the five defects reported by the audited tutorial of
the 1.0.1 installed library (`RELATORIO-AO-AUTOR.md` in the tutorial
project), each with a regression test in
`tests/testthat/test-regressions-102.R`. The 246-symbol public API is
unchanged; the 1.0.0 freeze and the 1.0.1 corrections remain the
historical reference.

#### Portable persistence

- `R/core-serialization.R`,
  [`smf_to_json()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md):
  added `na = "null"`. Without it, `NA_real_` was written as the text
  `"NA"`; a portable bundle saved under the default preprocessing
  (`impute_numeric = "none"`) validated and loaded but failed at
  prediction with `argumento não-numérico para operador binário`.
- `R/preprocess.R`,
  [`smf_apply_preprocessor()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md):
  the imputation state is coerced with
  [`as.numeric()`](https://rdrr.io/r/base/numeric.html) before the
  subassignment, tolerating textual/NULL values restored from bundles
  written by earlier versions.
- `R/tracking.R`, `.smf_atomic_write_json()`: same `na = "null"` hygiene
  for run records and manifests.

#### Tuning contract

- `R/tuning-core.R`,
  [`smf_tune()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md):
  a tuning objective that is not declared in `spec@metrics` now aborts
  with `smf_tuning_error` (class `TUNING_OBJECTIVE_NOT_IN_METRICS`) and
  lists the available metrics, instead of producing an all-NA archive
  column and a silently empty selection.
- `R/print-methods.R`, `print.TuningResult`: the “selected” line
  distinguishes “no trial produced finite objective values” from
  “explicit compromise required for multi-objective tuning”.

#### Interface and type

- `R/explain.R`,
  [`smf_pdp()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md)/[`smf_ice()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md):
  the `value` column keeps the numeric type for numeric predictors (text
  remains only for factors), matching
  [`smf_ale()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md);
  this also removes the internal
  [`as.character()`](https://rdrr.io/r/base/character.html) sensitivity
  to `OutDec`.
- `R/probabilistic-core.R`,
  [`smf_dist_interval()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md):
  the `point` representation is refused with `smf_capability_error`,
  like
  [`smf_dist_cdf()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md)
  on the same representation, instead of silently returning a degenerate
  `[m, m]` interval.
- `R/core-capabilities.R`,
  [`smf_backend_capabilities()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md):
  the unknown-engine message now lists the accepted engines and points
  to
  [`smf_available_model_adapters()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md).

## sciModelFlowR 1.0.1

### Patch release — local validation campaign corrections

Version 1.0.1 releases the 22 documented corrections produced by the
local validation campaign of the 1.0.0 source freeze (see
`DERIVED_PATCH_NOTES.md` for the full audit trail and preserved
originals). The frozen 1.0.0 source tree, hashes and release metadata
remain the historical reference; this patch does not expand or change
the 246-symbol public API.

#### Load/runtime blockers

- `R/resampling.R`: backtick-quoted the reserved word in
  `summary=list(\`repeat\`=…)\` (the package could not be
  parsed/installed).
- `R/bayesian-adapters.R` → `R/bayesian-core.R`: moved the
  `S7::method(print, GPFitResult)` and
  `S7::method(print, BARTFitResult)` registrations after their class
  definitions (load order blocker).
- `R/provenance.R`: `.smf_hardware_info()` no longer indexes the
  non-existent `Sys.info()[["model"]]` (run manifests, batch/resume,
  calibration and deployment paths aborted); CPU model falls back to
  `PROCESSOR_IDENTIFIER`/`machine`.
- `R/deep-learning-train.R`: `torch::nn_lazy_linear` is resolved at
  runtime with an explicit `TORCH_LAZY_UNSUPPORTED` capability error
  when the backend does not provide lazy modules.
- `R/scalability.R`: removed a `:::` self-reference in the parallel
  batch worker.

#### Scientific/numerical corrections

- `R/release-candidate.R`: the reference gate now fits on the holdout
  train rows and evaluates on the held-out test rows, matching the
  frozen fixture (the previous full-data fit leaked test rows and failed
  deterministically).
- `R/calibration.R`: isotonic calibration fits on score-ordered pairs
  (PAVA requires nondecreasing x) and degenerate all-zero rows fall back
  to the validated input row / uniform simplex instead of emitting
  zeros.
- `R/model-adapters.R`: `"linear"` is accepted as an alias of
  `"linear_regression"` in the stats and tidymodels adapters (used by
  vignettes and validators).
- `R/tuning-core.R`: the racing archive uses a homogeneous schema so the
  final `rbind` succeeds (racing previously never produced an archive).

#### Serialization/round-trip

- `R/core-serialization.R`: empty JSON/YAML arrays (`[]`) are mapped
  back to typed empty vectors via S7 property introspection, fixing
  cross-session round-trips (e.g. `DLGradientExplanation`,
  `ExplainSpec`, `DataSpec`) that failed because installed S7 class
  objects are not identical to session-created ones.

#### Packaging/build

- `inst/gold/` → `inst/gold_data/`, `inst/extdata/gold/` →
  `inst/extdata/gold_data/`, `inst/crosslang/gold/` →
  `inst/crosslang/gold_data/`: `R CMD build` drops directories whose
  name ends in `old`, so the frozen layout silently removed the complete
  Gold suite, cards, hashes and known truth from built tarballs. Dataset
  names (`gold_*`), file contents and hashes are unchanged.
- `man/`: kept the frozen topic pages (11 topics covering all 246
  exports); removed 246 empty per-function pages generated by a full
  `document()` run and three illustrative `\usage{}` blocks without
  `\arguments{}`; removed the broken single-line `smf_explain_api.Rd`.
- `vignettes/*.qmd`: added `vignette:` metadata with
  `%\VignetteEngine{quarto::html}` to all 28 articles and set
  `VignetteBuilder: quarto`; `R CMD build` now renders 28 HTML vignettes
  into `inst/doc` (previously zero) and the check rebuilds them.
- `DESCRIPTION`/`NAMESPACE`: `tibble`/`vctrs` moved from Imports to
  Suggests (unused); `import(stats)`/`import(utils)` added so codetools
  resolves base helpers; `LICENSE` reduced to the standard two-line stub
  (BSD-3-Clause text preserved in the validation records).
- `R/zzz.R`: declared NSE globals (`self`, ggplot2 column names) for
  `R CMD check`.

#### Teaching material and validation harness

- `inst/notebooks/jupyter/*.ipynb`: version assertion updated from
  `0.9.0` to the release version and metadata aligned; all 27 notebooks
  execute in clean IR kernels.
- `tools/validate_1.0.0.R`/`_release.R`: line-separated equivalents of
  the single-line frozen harnesses (literal `\n` sequences made them
  unparseable); originals preserved.
- `tests/testthat`: repaired two single-line test files; aligned stale
  constants (API freeze, backend matrix, Gold counts); replaced
  [`table()`](https://rdrr.io/r/base/table.html) identity comparisons;
  repaired type-strict expectations; updated the reference-scope and
  linear-alias expectations.
- Repository owner references and pkgdown URL moved to the published
  location (`https://github.com/wep69/sciModelFlowR`).

#### Validation summary (local campaign, Windows, R 4.6.0)

- `testthat`: 61 files, 299 pass / 0 fail (source and installed).
- Gold 25/25, cross-language 25/25, reference tolerances ~1e-15.
- `R CMD build` + `R CMD check --as-cran`: 0 ERROR / 0 WARNING / 2 NOTEs
  (new submission metadata; intentional top-level release documents).
- 28/28 vignettes, 27/27 notebooks, pkgdown site rebuilt.
- Historical 0.1.0–0.9.0 campaigns remain `NOT RUN` in this environment
  (their snapshots are not distributed with 1.0.x); GPU/CUDA and ONNX
  remain `SKIP`/`QUARANTINED`. The package is not claimed CRAN-ready.

## sciModelFlowR 1.0.0

### Consolidated Scientific Release

- Preserved the 246-export API frozen at 0.9.0; no intentional public
  signature expansion is introduced during consolidation.
- Added stable 1.x API freeze/diff metadata and a final compatibility
  matrix with explicit certification state.
- Added a static security-review ledger covering opaque serialization,
  portable bundles, deployment surfaces, artifact integrity, and
  external-service adapters.
- Added a frozen Gold release manifest and benchmark-baseline registry,
  while keeping runtime performance baselines pending actual execution.
- Completed pkgdown article navigation for the full vignette curriculum,
  including Deep Learning, Bayesian/conformal uncertainty, domain
  workflows, API governance, and validation.
- Added final release/migration/checklist documents and 1.0.0 validation
  entry points.
- Runtime, numerical, optional-backend, CPU/GPU,
  documentation-rendering, cross-platform, and CRAN-style certification
  remain explicitly pending until they are actually executed in the
  final local validation campaign.

## sciModelFlowR 0.9.0

### Integrated Scientific Release Candidate

- Added first-class protected external validation through
  `ExternalValidationResult`,
  [`smf_external_validate()`](https://wep69.github.io/sciModelFlowR/reference/external-validation-090.md),
  domain-shift diagnostics, and separate internal/external metric
  comparison without refitting or recalibration.
- Completed the publication-reporting layer with `ReportingResult`,
  publication tables/plots, a minimum scientific reporting checklist,
  Markdown/Quarto/HTML/PDF/DOCX/LaTeX reporting targets, CSV/Parquet
  table export, and explicit external-validation evidence.
- Added `ReleaseCandidateAudit`,
  [`smf_api_catalog()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md),
  [`smf_backend_matrix()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md),
  [`smf_run_reference_validation()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md),
  and
  [`smf_run_crosslang_validation()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md).
- Froze the release-candidate public API at 246 exports and distributed
  a machine-readable API manifest plus SHA-256.
- Marked optional backends as quarantined for release certification
  until the consolidated local runtime/numerical validation campaign is
  completed.
- Completed the formal Gold suite: 25 frozen datasets are distributed,
  covering all 20 specification scenarios plus five additional
  development fixtures.
- Added canonical cross-language schema, dataset, split-manifest,
  expected-metric, expected-prediction, tolerance, and algorithm-version
  fixtures.
- Added domain vignettes 21-24 for agronomy/soil,
  spectroscopy/phenotyping, spatial/environmental workflows, and
  protected external validation.
- Added vignette 25 API catalog, vignette 26 migration/deprecation
  guide, paired IRkernel curriculum through vignette 27, and
  release-candidate migration/security metadata.
- Added seven dedicated 0.9.0 test files and dedicated runtime,
  differential, curriculum, and release-candidate validation scripts.
- The 0.9.0 API is frozen for 1.0.0; subsequent source changes should be
  restricted to blocker corrections discovered during certification.
- Runtime, numerical, optional-backend, rendered-documentation, and
  CRAN-style certification remain intentionally deferred to the final
  local validation cycle.

## sciModelFlowR 0.8.0

### Tracking, persistence, deployment, and scalability

- Added `TrackingSpec`, `PersistenceSpec`, `DeploymentSpec`, and
  `ScalabilitySpec` without breaking older serialized `ExperimentSpec`
  payloads.
- Added a dependency-light local experiment tracker with
  start/log/end/list/get operations and explicit resume semantics;
  optional MLflow tracking remains outside the core dependency set.
- Added checksum-verified inference bundles with manifest,
  specification, schema, preprocessing, labels, run manifest, model
  state, and explicit bundle-schema version.
- Added a portable safe-state path for supported
  [`stats::lm()`](https://rdrr.io/r/stats/lm.html)/[`stats::glm()`](https://rdrr.io/r/stats/glm.html)
  workflows and explicit `trusted = TRUE` requirements for opaque R
  serialization.
- Added corrupted-checksum rejection, incompatible-major-schema
  rejection with migration guidance, and bundle metadata inspection
  before model loading.
- Added
  [`smf_predict_bundle()`](https://wep69.github.io/sciModelFlowR/reference/tracking-persistence-080.md)
  plus strict input-schema checking and bundle/live
  prediction-equivalence tests.
- Added replay of fitted probability calibration after trusted
  opaque-bundle reload, with differential prediction tests.
- Extended `RunManifest` with CPU/GPU/CUDA/torch hardware metadata.
- Added deterministic batch prediction, resumable checksum-verified
  batch checkpoints, row-order preservation, resettable data iterators,
  and optional process-parallel batch execution.
- Added optional `pins` publishing/fetching, guarded `vetiver` model/pin
  adapters, Plumber endpoint generation, and an explicit non-certified
  ONNX export hook.
- Added focused vignette 20, lesson contract, IRkernel notebook, five
  dedicated test files, and 0.8.0 runtime/scalability validation
  scripts.
- Runtime, numerical, optional-service, rendered-documentation, and
  CRAN-style certification remain intentionally deferred to the
  consolidated local validation cycle.

## sciModelFlowR 0.7.0

### Bayesian modeling, conformal prediction, and typed uncertainty

- Added `ConformalSpec` to the stable experiment grammar with
  backward-compatible deserialization of earlier experiment schemas.
- Added a package-native conjugate Gaussian Bayesian reference model
  plus optional `brms`/Stan execution, standardized posterior draws,
  posterior summaries, prior/posterior predictive workflows, MCMC
  diagnostic flags, PSIS-LOO, model comparison, and stacking.
- Added optional BART (`dbarts`) and Gaussian-process (`DiceKriging`)
  adapters plus a package-native fixed-hyperparameter GP reference
  implementation with identifiable predictive variance components.
- Added package-native split conformal, CV+, conformalized-quantile
  calibration, and deterministic APS classification prediction sets;
  full conformal is delegated to a compatible backend because it
  requires candidate-outcome refitting.
- Added strict calibration/final-test overlap guards, design-aware
  exchangeability warnings, coverage/width diagnostics, and structured
  undercoverage warnings.
- Added typed uncertainty descriptors and validation so confidence,
  credible, posterior predictive, bootstrap, prediction, and conformal
  intervals remain scientifically distinct.
- Added aleatoric/epistemic decomposition only when identifiability is
  explicit.
- Added `gold_bayesian_linear`, `gold_conformal_regression`, three
  cross-language semantic fixtures, four focused vignettes, lesson
  contracts, IRkernel notebooks, and dedicated 0.7.0 runtime/simulation
  validation scripts.
- Runtime, numerical, optional-backend, rendered-documentation, and
  CRAN-style certification remain intentionally deferred to the
  consolidated local validation cycle.

## sciModelFlowR 0.6.0

### Deep Learning and probabilistic Deep Learning

- Added package-native `DeepLearningSpec`, architecture, history,
  checkpoint, fit, ensemble, uncertainty, and gradient-explanation
  contracts.
- Added MLP, CNN1D/2D, RNN, LSTM, GRU, TCN, Transformer, ViT,
  autoencoder, VAE, transfer-learning, multimodal, and multitask
  architecture declarations/builders.
- Added a torch-native tabular trainer plus N-dimensional tensor
  training/prediction for structured sequence, spectral, and image
  inputs, with explicit architecture-shape validation.
- Added development-validation guards so final/external test data cannot
  drive early stopping, schedulers, or checkpoint selection.
- Added optimizers, schedulers, gradient clipping, early stopping,
  checkpoint/restart metadata, device and deterministic policies, and
  mixed-precision pathways.
- Added safe checkpoint metadata and SHA-256 verification; backend
  checkpoint loading remains opt-in through `trusted = TRUE`.
- Added explicit optional `luz` and `keras3` adapter surfaces.
- Added Gaussian distributional heads, MC dropout, deep ensembles,
  predictive intervals, and aleatoric/epistemic decomposition where the
  model supports it.
- Added saliency, Integrated Gradients, gradient × input, and explicit
  Grad-CAM interfaces, with non-causal interpretation recorded in
  package-native results.
- Added `gold_dl_nonlinear` and `gold_dl_sequence`, two Deep Learning
  architecture/head cross-language fixtures, four focused vignettes,
  lesson contracts, IRkernel notebooks, and dedicated validation
  scripts/tests.
- Runtime, numerical, CPU/GPU, optional-backend, rendered-documentation,
  and CRAN-style certification remain intentionally deferred to the
  consolidated local validation cycle.

## sciModelFlowR 0.5.0

### Explainable AI and explanation stability

- Added `ExplainSpec`, `ExplainResult`, and `ExplanationStabilityResult`
  S7 contracts and an `explain` component in `ExperimentSpec`, with
  backward-compatible deserialization of earlier experiment schemas.
- Added package-native permutation importance, partial dependence, ICE,
  one-dimensional ALE, local perturbation explanations, observed-data
  counterfactual candidates, source-feature tracing, explanation-domain
  diagnostics, and optional SHAP support through `fastshap`.
- Added structured correlated-feature warnings and explicit
  `causal_interpretation = FALSE` on package-native explanations.
- Added explanation-stability analysis across design-aware resamples
  with mean/SD/CV importance, positive-importance frequency, rank
  dispersion, pairwise Spearman rank agreement, and top-k Jaccard
  stability.
- Added the deterministic `gold_xai_stability` fixture and a
  cross-language XAI semantic fixture.
- Added focused vignette 10, lesson contract, IRkernel notebook, four
  dedicated test files, and final-cycle runtime/simulation validation
  scripts.
- Runtime, numerical, optional-backend, rendered-documentation, and
  CRAN-style certification remain intentionally deferred to the
  consolidated local validation cycle.

## sciModelFlowR 0.4.0

### Tuning and scientific benchmarking

- Added `SearchSpace`, `TuningSpec`, `BenchmarkSpec`, `TuningResult`,
  `NestedTuningResult`, and `BenchmarkResult` contracts.
- Added continuous, integer, factor, logical, logarithmic, conditional,
  and resource-aware search domains with nested parameter-path updates.
- Added package-native grid and random search, sequential racing,
  Gaussian-process Bayesian optimization with expected improvement,
  successive halving, and Hyperband.
- Added explicit multi-objective optimization, Pareto-front retention,
  weighted-sum and lexicographic compromise rules, with no automatic
  universal winner for conflicting objectives.
- Added nested tuning with separate inner-selection and
  outer-generalization outputs plus distinct split hashes.
- Added scientific benchmarking on shared resamples with uncertainty
  summaries, compute accounting, fold-level rank stability, Pareto
  evidence, and explicit decision-rule replay.
- Added leakage guards that reject final/external assessment data from
  managed tuning and development benchmarking.
- Added cross-language search-space and Pareto fixtures.
- Added focused vignettes 08 and 19, lesson contracts, IRkernel notebook
  sources, and dedicated 0.4.0 tests/validation scripts.
- Runtime and numerical certification remain intentionally deferred to
  the consolidated local validation cycle for the complete package
  series.

## sciModelFlowR 0.3.0

### Supervised ML and probabilistic foundation

- Added package-native supervised adapters for `stats`,
  `tidymodels`/`parsnip`, `mlr3`, and XGBoost, with optional backends
  isolated from the core dependency set.
- Added binary and multiclass probability contracts, multi-output
  regression support through the core `stats` adapter, and standardized
  model prediction dispatch.
- Stabilized `PredictionDistribution` operations for point, parametric,
  sample, quantile, interval, and class-probability representations.
- Added probabilistic scoring for log loss, Brier score, ECE, Gaussian
  NLL/CRPS, interval coverage, width, and interval score.
- Added Platt, isotonic, and multinomial probability calibration with
  calibration data separated from final assessment labels. Beta
  calibration remains an explicitly optional adapter target.
- Added fold-safe class weights, random under/over-sampling,
  SMOTE-family adapters through `themis`, and explicit threshold
  optimization on calibration/validation data.
- Added the frozen `gold_multiclass_imbalanced` teaching/validation
  dataset.
- Added focused vignettes 06, 07, and 09 plus 0.3.0 validation scripts
  and tests.
- Runtime and numerical certification remain intentionally deferred to
  the consolidated local validation cycle requested for the final
  package series.

## sciModelFlowR 0.2.0

### Resampling and scientific design

- Added ordinary/repeated V-fold, stratified, grouped, blocked,
  temporal, spatial, external, Monte Carlo, and nested resampling
  pathways.
- Added package-native `ResampleCollection` and `ResampleResult`
  contracts plus stable split manifests.
- Added blocking guards for row-wise random validation under
  grouped/repeated, temporal, and spatial designs.
- Added
  [`smf_resample_experiment()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md)
  with preprocessing and feature learning fitted independently inside
  each analysis fold.

### Bootstrap and stability

- Added `BootstrapResult` and design-aware bootstrap validation.
- Added case, stratified, cluster, hierarchical, moving-block,
  stationary-block, and spatial-block index resampling.
- Added explicit generator contracts for residual, parametric, and wild
  bootstrap.
- Added percentile/basic intervals, case-bootstrap BCa, studentized
  intervals with replicate-specific standard errors, failure accounting,
  and stability diagnostics versus replicate count.
- Kept dependence-specific BCa paths blocked when a scientifically valid
  jackknife is not implemented.

### Feature engineering and selection

- Added `FeatureSpec`, `FeatureSelectionResult`, and
  `RepresentationResult`.
- Added near-zero-variance, correlation, VIF, mutual-information,
  package-native RFE, forward/backward sequential selection, optional
  regularized, optional tree, stability, PCA, and PLS pathways.
- Added guards that require learned feature operations to be fitted in
  training context unless externally fixed.
- Added
  [`smf_apply_representation()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md)
  so PCA/PLS states learned on analysis data are applied unchanged to
  assessment and future prediction data.
- Added feature-state retention in `FitResult` so
  [`smf_predict()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md)
  reproduces the fitted feature pipeline.

### Documentation, tests, and validation assets

- Updated the integrating vignette for the completed 0.2.0 scope.
- Completed focused vignettes 02 to 05 under the 60 to 70 percent length
  contract relative to the integrating tutorial.
- Added lesson contracts and IRkernel notebook sources for the new
  scientific modules.
- Added dedicated tests for RFE/sequential selection, PCA state
  transfer, studentized bootstrap, design-aware resampling, bootstrap
  guards, feature stability, and integrated resampling.
- Added final-version local validation and simulation-validation
  scripts.
- Runtime/numerical validation is deliberately deferred to the
  consolidated local validation cycle for all versions.

## sciModelFlowR 0.1.0

### Foundations, data, design, and API contracts

- Added the formal S7 specification system for data, task, design,
  preprocessing, resampling, bootstrap, models, probabilistic modeling,
  Bayesian modeling, deep learning, metrics, uncertainty,
  reproducibility, and experiments.
- Added typed scientific warning records and condition helpers.
- Added a capability registry independent of optional modeling backends.
- Added portable JSON/YAML serialization, hashing, and isolated RNG
  helpers.
- Added data auditing, schema checks, duplicate/missingness summaries,
  and leakage screens.
- Added design validation for groups, blocks, repeated units, time,
  coordinates, hierarchy, and external domains.
- Added training-only preprocessing and immutable holdout split records.
- Added package-native results, reference `lm`/`glm` adapters,
  diagnostics, manifests, six Gold datasets, and cross-language
  fixtures.
- Final source audit corrected S7 class introspection/serialization and
  removed RNG consumption from run-ID generation.
- Runtime certification remains a separate local/CI gate.
