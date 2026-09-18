# sciModelFlowR 1.0.0

## Consolidated Scientific Release

- Preserved the 246-export API frozen at 0.9.0; no intentional public signature expansion is introduced during consolidation.
- Added stable 1.x API freeze/diff metadata and a final compatibility matrix with explicit certification state.
- Added a static security-review ledger covering opaque serialization, portable bundles, deployment surfaces, artifact integrity, and external-service adapters.
- Added a frozen Gold release manifest and benchmark-baseline registry, while keeping runtime performance baselines pending actual execution.
- Completed pkgdown article navigation for the full vignette curriculum, including Deep Learning, Bayesian/conformal uncertainty, domain workflows, API governance, and validation.
- Added final release/migration/checklist documents and 1.0.0 validation entry points.
- Runtime, numerical, optional-backend, CPU/GPU, documentation-rendering, cross-platform, and CRAN-style certification remain explicitly pending until they are actually executed in the final local validation campaign.

# sciModelFlowR 0.9.0

## Integrated Scientific Release Candidate

- Added first-class protected external validation through `ExternalValidationResult`, `smf_external_validate()`, domain-shift diagnostics, and separate internal/external metric comparison without refitting or recalibration.
- Completed the publication-reporting layer with `ReportingResult`, publication tables/plots, a minimum scientific reporting checklist, Markdown/Quarto/HTML/PDF/DOCX/LaTeX reporting targets, CSV/Parquet table export, and explicit external-validation evidence.
- Added `ReleaseCandidateAudit`, `smf_api_catalog()`, `smf_backend_matrix()`, `smf_run_reference_validation()`, and `smf_run_crosslang_validation()`.
- Froze the release-candidate public API at 246 exports and distributed a machine-readable API manifest plus SHA-256.
- Marked optional backends as quarantined for release certification until the consolidated local runtime/numerical validation campaign is completed.
- Completed the formal Gold suite: 25 frozen datasets are distributed, covering all 20 specification scenarios plus five additional development fixtures.
- Added canonical cross-language schema, dataset, split-manifest, expected-metric, expected-prediction, tolerance, and algorithm-version fixtures.
- Added domain vignettes 21-24 for agronomy/soil, spectroscopy/phenotyping, spatial/environmental workflows, and protected external validation.
- Added vignette 25 API catalog, vignette 26 migration/deprecation guide, paired IRkernel curriculum through vignette 27, and release-candidate migration/security metadata.
- Added seven dedicated 0.9.0 test files and dedicated runtime, differential, curriculum, and release-candidate validation scripts.
- The 0.9.0 API is frozen for 1.0.0; subsequent source changes should be restricted to blocker corrections discovered during certification.
- Runtime, numerical, optional-backend, rendered-documentation, and CRAN-style certification remain intentionally deferred to the final local validation cycle.

# sciModelFlowR 0.8.0

## Tracking, persistence, deployment, and scalability

- Added `TrackingSpec`, `PersistenceSpec`, `DeploymentSpec`, and `ScalabilitySpec` without breaking older serialized `ExperimentSpec` payloads.
- Added a dependency-light local experiment tracker with start/log/end/list/get operations and explicit resume semantics; optional MLflow tracking remains outside the core dependency set.
- Added checksum-verified inference bundles with manifest, specification, schema, preprocessing, labels, run manifest, model state, and explicit bundle-schema version.
- Added a portable safe-state path for supported `stats::lm()`/`stats::glm()` workflows and explicit `trusted = TRUE` requirements for opaque R serialization.
- Added corrupted-checksum rejection, incompatible-major-schema rejection with migration guidance, and bundle metadata inspection before model loading.
- Added `smf_predict_bundle()` plus strict input-schema checking and bundle/live prediction-equivalence tests.
- Added replay of fitted probability calibration after trusted opaque-bundle reload, with differential prediction tests.
- Extended `RunManifest` with CPU/GPU/CUDA/torch hardware metadata.
- Added deterministic batch prediction, resumable checksum-verified batch checkpoints, row-order preservation, resettable data iterators, and optional process-parallel batch execution.
- Added optional `pins` publishing/fetching, guarded `vetiver` model/pin adapters, Plumber endpoint generation, and an explicit non-certified ONNX export hook.
- Added focused vignette 20, lesson contract, IRkernel notebook, five dedicated test files, and 0.8.0 runtime/scalability validation scripts.
- Runtime, numerical, optional-service, rendered-documentation, and CRAN-style certification remain intentionally deferred to the consolidated local validation cycle.

# sciModelFlowR 0.7.0

## Bayesian modeling, conformal prediction, and typed uncertainty

- Added `ConformalSpec` to the stable experiment grammar with backward-compatible deserialization of earlier experiment schemas.
- Added a package-native conjugate Gaussian Bayesian reference model plus optional `brms`/Stan execution, standardized posterior draws, posterior summaries, prior/posterior predictive workflows, MCMC diagnostic flags, PSIS-LOO, model comparison, and stacking.
- Added optional BART (`dbarts`) and Gaussian-process (`DiceKriging`) adapters plus a package-native fixed-hyperparameter GP reference implementation with identifiable predictive variance components.
- Added package-native split conformal, CV+, conformalized-quantile calibration, and deterministic APS classification prediction sets; full conformal is delegated to a compatible backend because it requires candidate-outcome refitting.
- Added strict calibration/final-test overlap guards, design-aware exchangeability warnings, coverage/width diagnostics, and structured undercoverage warnings.
- Added typed uncertainty descriptors and validation so confidence, credible, posterior predictive, bootstrap, prediction, and conformal intervals remain scientifically distinct.
- Added aleatoric/epistemic decomposition only when identifiability is explicit.
- Added `gold_bayesian_linear`, `gold_conformal_regression`, three cross-language semantic fixtures, four focused vignettes, lesson contracts, IRkernel notebooks, and dedicated 0.7.0 runtime/simulation validation scripts.
- Runtime, numerical, optional-backend, rendered-documentation, and CRAN-style certification remain intentionally deferred to the consolidated local validation cycle.

# sciModelFlowR 0.6.0

## Deep Learning and probabilistic Deep Learning

- Added package-native `DeepLearningSpec`, architecture, history, checkpoint, fit, ensemble, uncertainty, and gradient-explanation contracts.
- Added MLP, CNN1D/2D, RNN, LSTM, GRU, TCN, Transformer, ViT, autoencoder, VAE, transfer-learning, multimodal, and multitask architecture declarations/builders.
- Added a torch-native tabular trainer plus N-dimensional tensor training/prediction for structured sequence, spectral, and image inputs, with explicit architecture-shape validation.
- Added development-validation guards so final/external test data cannot drive early stopping, schedulers, or checkpoint selection.
- Added optimizers, schedulers, gradient clipping, early stopping, checkpoint/restart metadata, device and deterministic policies, and mixed-precision pathways.
- Added safe checkpoint metadata and SHA-256 verification; backend checkpoint loading remains opt-in through `trusted = TRUE`.
- Added explicit optional `luz` and `keras3` adapter surfaces.
- Added Gaussian distributional heads, MC dropout, deep ensembles, predictive intervals, and aleatoric/epistemic decomposition where the model supports it.
- Added saliency, Integrated Gradients, gradient × input, and explicit Grad-CAM interfaces, with non-causal interpretation recorded in package-native results.
- Added `gold_dl_nonlinear` and `gold_dl_sequence`, two Deep Learning architecture/head cross-language fixtures, four focused vignettes, lesson contracts, IRkernel notebooks, and dedicated validation scripts/tests.
- Runtime, numerical, CPU/GPU, optional-backend, rendered-documentation, and CRAN-style certification remain intentionally deferred to the consolidated local validation cycle.

# sciModelFlowR 0.5.0

## Explainable AI and explanation stability

- Added `ExplainSpec`, `ExplainResult`, and `ExplanationStabilityResult` S7 contracts and an `explain` component in `ExperimentSpec`, with backward-compatible deserialization of earlier experiment schemas.
- Added package-native permutation importance, partial dependence, ICE, one-dimensional ALE, local perturbation explanations, observed-data counterfactual candidates, source-feature tracing, explanation-domain diagnostics, and optional SHAP support through `fastshap`.
- Added structured correlated-feature warnings and explicit `causal_interpretation = FALSE` on package-native explanations.
- Added explanation-stability analysis across design-aware resamples with mean/SD/CV importance, positive-importance frequency, rank dispersion, pairwise Spearman rank agreement, and top-k Jaccard stability.
- Added the deterministic `gold_xai_stability` fixture and a cross-language XAI semantic fixture.
- Added focused vignette 10, lesson contract, IRkernel notebook, four dedicated test files, and final-cycle runtime/simulation validation scripts.
- Runtime, numerical, optional-backend, rendered-documentation, and CRAN-style certification remain intentionally deferred to the consolidated local validation cycle.

# sciModelFlowR 0.4.0

## Tuning and scientific benchmarking

- Added `SearchSpace`, `TuningSpec`, `BenchmarkSpec`, `TuningResult`, `NestedTuningResult`, and `BenchmarkResult` contracts.
- Added continuous, integer, factor, logical, logarithmic, conditional, and resource-aware search domains with nested parameter-path updates.
- Added package-native grid and random search, sequential racing, Gaussian-process Bayesian optimization with expected improvement, successive halving, and Hyperband.
- Added explicit multi-objective optimization, Pareto-front retention, weighted-sum and lexicographic compromise rules, with no automatic universal winner for conflicting objectives.
- Added nested tuning with separate inner-selection and outer-generalization outputs plus distinct split hashes.
- Added scientific benchmarking on shared resamples with uncertainty summaries, compute accounting, fold-level rank stability, Pareto evidence, and explicit decision-rule replay.
- Added leakage guards that reject final/external assessment data from managed tuning and development benchmarking.
- Added cross-language search-space and Pareto fixtures.
- Added focused vignettes 08 and 19, lesson contracts, IRkernel notebook sources, and dedicated 0.4.0 tests/validation scripts.
- Runtime and numerical certification remain intentionally deferred to the consolidated local validation cycle for the complete package series.

# sciModelFlowR 0.3.0

## Supervised ML and probabilistic foundation

- Added package-native supervised adapters for `stats`, `tidymodels`/`parsnip`, `mlr3`, and XGBoost, with optional backends isolated from the core dependency set.
- Added binary and multiclass probability contracts, multi-output regression support through the core `stats` adapter, and standardized model prediction dispatch.
- Stabilized `PredictionDistribution` operations for point, parametric, sample, quantile, interval, and class-probability representations.
- Added probabilistic scoring for log loss, Brier score, ECE, Gaussian NLL/CRPS, interval coverage, width, and interval score.
- Added Platt, isotonic, and multinomial probability calibration with calibration data separated from final assessment labels. Beta calibration remains an explicitly optional adapter target.
- Added fold-safe class weights, random under/over-sampling, SMOTE-family adapters through `themis`, and explicit threshold optimization on calibration/validation data.
- Added the frozen `gold_multiclass_imbalanced` teaching/validation dataset.
- Added focused vignettes 06, 07, and 09 plus 0.3.0 validation scripts and tests.
- Runtime and numerical certification remain intentionally deferred to the consolidated local validation cycle requested for the final package series.

# sciModelFlowR 0.2.0

## Resampling and scientific design

* Added ordinary/repeated V-fold, stratified, grouped, blocked, temporal, spatial, external, Monte Carlo, and nested resampling pathways.
* Added package-native `ResampleCollection` and `ResampleResult` contracts plus stable split manifests.
* Added blocking guards for row-wise random validation under grouped/repeated, temporal, and spatial designs.
* Added `smf_resample_experiment()` with preprocessing and feature learning fitted independently inside each analysis fold.

## Bootstrap and stability

* Added `BootstrapResult` and design-aware bootstrap validation.
* Added case, stratified, cluster, hierarchical, moving-block, stationary-block, and spatial-block index resampling.
* Added explicit generator contracts for residual, parametric, and wild bootstrap.
* Added percentile/basic intervals, case-bootstrap BCa, studentized intervals with replicate-specific standard errors, failure accounting, and stability diagnostics versus replicate count.
* Kept dependence-specific BCa paths blocked when a scientifically valid jackknife is not implemented.

## Feature engineering and selection

* Added `FeatureSpec`, `FeatureSelectionResult`, and `RepresentationResult`.
* Added near-zero-variance, correlation, VIF, mutual-information, package-native RFE, forward/backward sequential selection, optional regularized, optional tree, stability, PCA, and PLS pathways.
* Added guards that require learned feature operations to be fitted in training context unless externally fixed.
* Added `smf_apply_representation()` so PCA/PLS states learned on analysis data are applied unchanged to assessment and future prediction data.
* Added feature-state retention in `FitResult` so `smf_predict()` reproduces the fitted feature pipeline.

## Documentation, tests, and validation assets

* Updated the integrating vignette for the completed 0.2.0 scope.
* Completed focused vignettes 02 to 05 under the 60 to 70 percent length contract relative to the integrating tutorial.
* Added lesson contracts and IRkernel notebook sources for the new scientific modules.
* Added dedicated tests for RFE/sequential selection, PCA state transfer, studentized bootstrap, design-aware resampling, bootstrap guards, feature stability, and integrated resampling.
* Added final-version local validation and simulation-validation scripts.
* Runtime/numerical validation is deliberately deferred to the consolidated local validation cycle for all versions.

# sciModelFlowR 0.1.0

## Foundations, data, design, and API contracts

* Added the formal S7 specification system for data, task, design, preprocessing, resampling, bootstrap, models, probabilistic modeling, Bayesian modeling, deep learning, metrics, uncertainty, reproducibility, and experiments.
* Added typed scientific warning records and condition helpers.
* Added a capability registry independent of optional modeling backends.
* Added portable JSON/YAML serialization, hashing, and isolated RNG helpers.
* Added data auditing, schema checks, duplicate/missingness summaries, and leakage screens.
* Added design validation for groups, blocks, repeated units, time, coordinates, hierarchy, and external domains.
* Added training-only preprocessing and immutable holdout split records.
* Added package-native results, reference `lm`/`glm` adapters, diagnostics, manifests, six Gold datasets, and cross-language fixtures.
* Final source audit corrected S7 class introspection/serialization and removed RNG consumption from run-ID generation.
* Runtime certification remains a separate local/CI gate.
