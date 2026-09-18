# sciModelFlowR
## Formal Scientific and Technical Implementation Proposal
### R counterpart to `sciModelFlow` Python, roadmap 0.1.0 to 1.0.0 Consolidated Scientific Release

**Document status:** pre-code architectural proposal  
**Language of this proposal:** Portuguese  
**Package implementation language:** R  
**Public API, code, package metadata, help pages, vignettes and user-facing diagnostics:** English  
**Specification date:** 2026-09-14  
**Provisional CRAN package name:** `sciModelFlowR`  
**Project-family name:** `sciModelFlow`  
**Target release:** 1.0.0 Consolidated Scientific Release  
**Current implementation status:** no R package code is claimed as implemented or runtime-validated in this proposal.

> The Python specification is the scientific-semantic reference. The R package must preserve scientific meaning, validation geometry, uncertainty semantics, result contracts and release gates, but it must not be a line-by-line translation of Python code or backend APIs.

---

# 1. Executive decision

The recommended R package is **`sciModelFlowR`**, a scientific workflow framework for deterministic machine learning, probabilistic prediction, bootstrap inference, Bayesian modeling, Deep Learning, uncertainty quantification, calibration, conformal prediction, model diagnostics, explainability, benchmarking, provenance, reproducibility and scientific reporting.

Its defining contribution is not a new collection of estimators. It is a **scientific orchestration layer** that encodes experimental and observational design before model fitting, prevents leakage, enforces design-aware validation, standardizes uncertainty semantics, preserves provenance and exposes a common result system across heterogeneous R backends.

The R package should preserve the four first-class inferential paradigms of the Python architecture from the beginning:

1. deterministic predictive modeling;
2. bootstrap and repeated-resampling inference;
3. probabilistic prediction;
4. Bayesian modeling.

They must share the same task, design, data, prediction, evidence, result, warning, provenance and reporting contracts.

---

# 2. Naming recommendation

## 2.1 Recommended name

**CRAN package:** `sciModelFlowR`

Reasons:

- clearly distinguishes the R implementation from the Python distribution;
- keeps both projects visibly in the same software family;
- avoids ambiguity in articles, tutorials, repositories and citations;
- allows deliberate cross-language parity tests without pretending the implementations are identical;
- leaves open the possibility of a future umbrella website named `sciModelFlow`.

## 2.2 Alternative

Using `sciModelFlow` on both CRAN and PyPI is technically conceptually attractive because the ecosystems are separate. If that identity is preferred, the name should be frozen **before version 0.1.0**, because renaming after public release would create unnecessary migration costs.

## 2.3 Function prefix

Use the concise public prefix `smf_` for constructors and high-level verbs. Standard R generics such as `print()`, `summary()`, `plot()`, `predict()`, `autoplot()`, `tidy()`, `glance()` and `augment()` can have package methods.

---

# 3. Scientific mission

`sciModelFlowR` will help researchers move from a scientific question and declared experimental/observational design to a defensible model, uncertainty assessment, diagnostic evaluation, interpretation and reproducible report.

Primary target domains are Agronomy, Soil Science, environmental modeling, remote sensing, spectroscopy, phenotyping, plant physiology, plant stress, climate science and related quantitative sciences, while the architecture remains general enough for other scientific fields.

The package is explicitly **not** intended to be:

- generic AutoML;
- a replacement for tidymodels, mlr3, torch, keras3, Stan/brms or specialized model packages;
- a causal-inference engine by default;
- an automatic publication decision system;
- a system that silently repairs invalid scientific designs;
- a universal deployment platform.

---

# 4. Architectural principle: semantic parity, not syntactic imitation

The Python and R implementations should align on:

- scientific concepts;
- task definitions;
- design declarations;
- parameter meaning;
- uncertainty types;
- dataset names;
- expected output concepts;
- Gold datasets;
- validation scenarios;
- benchmark definitions;
- algorithm-version identifiers;
- portable manifests;
- reporting terminology.

They should **not** be forced to align on:

- internal class systems;
- exact function signatures where R conventions differ;
- random-number streams;
- storage formats that are backend-specific;
- notebook technology;
- object mutation mechanics;
- backend-native fit objects.

Cross-language validation must therefore compare **scientific quantities and contracts**, not incidental implementation details.

---

# 5. Core scientific principles

1. **Design before algorithm.** Groups, blocks, repeated units, hierarchy, time, space and external domains are declared before resampling.
2. **Training-only learning.** Imputation, scaling, encoding, feature selection, oversampling and all learned preprocessing occur inside the training partition of each resample.
3. **The test set is not a tuning resource.**
4. **Uncertainty is typed.** Confidence, credible, prediction, conformal and resampling intervals are never interchangeable.
5. **Backend capabilities are explicit.** Unsupported operations fail clearly.
6. **Backend independence is architectural.** Ordinary users should not manipulate backend-native objects.
7. **Reproducibility is an output.** Every managed experiment emits a manifest.
8. **Diagnostics precede interpretation.**
9. **Observed data remain visible whenever scientifically appropriate.**
10. **Model quality is multidimensional.** Performance, calibration, uncertainty, stability, compute cost and external validity are treated separately.
11. **XAI is not causal inference.**
12. **Complexity must solve a stated scientific problem.**
13. **Unsafe persistence is never the default.**
14. **Teaching and production use the same public API.**
15. **R/Python parity is validated numerically where parity is scientifically meaningful.**

---

# 6. Proposed R architecture

```text
                           sciModelFlowR
                                |
                     Scientific Workflow Engine
                                |
       +------------------------+-------------------------+
       |                        |                         |
  Data and Design         Modeling Layer            Inference Layer
       |                        |                         |
   DataSpec               Deterministic ML            Resampling
   TaskSpec               Probabilistic ML            Bootstrap
   DesignSpec             Deep Learning               Bayesian
   PreprocessSpec         Bayesian ML                 Conformal
   FeatureSpec            Probabilistic DL            Calibration
       |                        |                         |
       +------------------------+-------------------------+
                                |
                       Unified Result System
                                |
                  Diagnostics and Typed Uncertainty
                                |
             Explanation, Benchmarking and Reporting
                                |
                Reproducibility, Tracking, Persistence
```

The dependency direction must point inward. Backend adapters may depend on heavy optional packages; core specifications and result classes must not.

---

# 7. Object system: S7 where it provides real value

## 7.1 Recommendation

Use **S7** for the package-native contracts that require validated properties, formal inheritance and stable dispatch:

- specification objects;
- result envelopes;
- uncertainty descriptors;
- capability sets;
- warning records;
- prediction-distribution objects;
- experiment composition objects.

Use S3-compatible generics/methods for conventional R ergonomics and ecosystem interoperability.

## 7.2 Why S7 is advantageous here

The package has many structured contracts whose validity should be checked at construction time. S7 provides formal class definitions, properties, validators and compatibility with S3/S4 classes. This is a better fit than using unvalidated nested lists for scientific contracts.

## 7.3 Immutability policy

Specification objects should be **immutable by public contract**:

- no public mutation helpers;
- construction-time validation;
- update helpers return a new object;
- internal setters, when unavoidable, remain non-exported;
- hashes are invalidated whenever a new specification object is created.

Result objects may contain references to backend state, but their scientific metadata and manifest records are treated as immutable after completion.

## 7.4 S3 interoperability

Provide methods where meaningful for:

```r
print()
summary()
predict()
plot()
autoplot()
tidy()
glance()
augment()
```

The backend fit remains accessible only through an explicit escape hatch such as `smf_backend_object()`.

---

# 8. Core S7 specification registry

| S7 class | R constructor | Purpose | Stability target |
|---|---|---|---|
| `DataSpec` | `smf_data_spec()` | variable roles, targets, IDs, units, missing-value codes | 0.1.0 |
| `TaskSpec` | `smf_task_spec()` | regression, classification, count, multi-output and probabilistic objective | 0.1.0 |
| `DesignSpec` | `smf_design_spec()` | groups, clusters, blocks, hierarchy, repeated unit, time, coordinates, external domains | 0.1.0 |
| `PreprocessSpec` | `smf_preprocess_spec()` | imputation, encoding, scaling, transformations, ordering | 0.1.0 |
| `FeatureSpec` | `smf_feature_spec()` | feature selection, representation, interactions, domain features | 0.2.0 |
| `ResamplingSpec` | `smf_resampling_spec()` | outer/inner CV geometry | schema 0.1.0, full 0.2.0 |
| `BootstrapSpec` | `smf_bootstrap_spec()` | bootstrap unit, dependence, statistic, B, intervals | schema 0.1.0, engine 0.2.0 |
| `ModelSpec` | `smf_model_spec()` | model family, engine, fixed parameters, stochastic controls | 0.1.0 |
| `ProbabilisticSpec` | `smf_probabilistic_spec()` | distributions, quantiles, probabilistic scores | schema 0.1.0, full 0.3.0 |
| `BayesianSpec` | `smf_bayesian_spec()` | priors, inference, chains/draws, diagnostics | schema 0.1.0, full 0.7.0 |
| `DeepLearningSpec` | `smf_dl_spec()` | architecture, trainer, optimizer, precision, device | schema 0.1.0, full 0.6.0 |
| `SearchSpace` | `smf_search_space()` | conditional hyperparameter domains | 0.4.0 |
| `TuningSpec` | `smf_tuning_spec()` | optimizer, budget, pruning, inner resampling, objectives | 0.4.0 |
| `MetricSpec` | `smf_metric_spec()` | metrics, direction, aggregation, decision role | 0.1.0 |
| `CalibrationSpec` | `smf_calibration_spec()` | calibration method and validation source | 0.3.0 |
| `ConformalSpec` | `smf_conformal_spec()` | conformal method, coverage, calibration partition | 0.7.0 |
| `UncertaintySpec` | `smf_uncertainty_spec()` | uncertainty target and admissible methods | 0.1.0 |
| `ExplainSpec` | `smf_explain_spec()` | XAI method, scope, background and stability resampling | 0.5.0 |
| `BenchmarkSpec` | `smf_benchmark_spec()` | candidates, metrics, decision rules and compute measures | 0.4.0 |
| `ReproducibilitySpec` | `smf_reproducibility_spec()` | RNG policy, hashing, environment capture | 0.1.0 |
| `ReportingSpec` | `smf_reporting_spec()` | report sections, tables, plots and formats | minimal 0.3.0, full 0.9.0 |
| `ExperimentSpec` | `smf_experiment_spec()` | composition root | 0.1.0 |

---

# 9. High-level public API

The public API should remain compact. Representative functions:

```r
smf_audit_data()
smf_validate_schema()
smf_validate_design()
smf_detect_leakage()

smf_build_preprocessor()
smf_make_resampler()
smf_make_nested_resampler()
smf_split_manifest()

smf_fit_experiment()
smf_bootstrap()
smf_predict_distribution()
smf_diagnose()
smf_explain()
smf_tune()
smf_benchmark()
smf_calibrate()
smf_conformalize()
smf_report()

smf_save_bundle()
smf_load_bundle()
smf_validate_bundle()

smf_load_dataset()
smf_dataset_card()
smf_run_gold_validation()
smf_run_reference_validation()
smf_capabilities()
smf_doctor()
```

Standard `predict()` should dispatch on fitted/result objects.

## 9.1 Example conceptual workflow

```r
spec <- smf_experiment_spec(
  task = smf_task_spec("regression", target = "yield"),
  data = smf_data_spec(...),
  design = smf_design_spec(groups = c("field", "season")),
  preprocessing = smf_preprocess_spec(...),
  resampling = smf_resampling_spec("group_vfold", v = 5),
  model = smf_model_spec("boost_tree", engine = "xgboost"),
  metrics = c("rmse", "mae")
)

result <- smf_fit_experiment(spec, data)
smf_diagnose(result)
predict(result, new_data)
smf_explain(result)
smf_report(result)
```

The teaching point remains that `field` and `season` define validation geometry before model ranking.

---

# 10. Unified result system

## 10.1 Common result metadata

Every package-native result should include a `ResultMeta` contract containing at least:

```text
run_id
created_at
package_version
schema_version
algorithm_version
backend
backend_version
data_hash_native
data_hash_portable
split_hash
spec_hash
rng_kind
random_seed
warnings
provenance
```

## 10.2 Required result classes

- `DataAuditResult`
- `FitResult`
- `PredictionResult`
- `PredictionDistribution`
- `ResampleResult`
- `BootstrapResult`
- `PosteriorResult`
- `CalibrationResult`
- `ConformalResult`
- `DiagnosticResult`
- `ExplainResult`
- `ExplanationStabilityResult`
- `TuningResult`
- `BenchmarkResult`
- `TrainingResult`
- `ExperimentResult`
- `RunManifest`

## 10.3 Tidy extraction

Each result should expose predictable tabular extractors such as:

```r
smf_metrics(result)
smf_predictions(result)
smf_intervals(result)
smf_warnings(result)
smf_manifest(result)
smf_diagnostics(result)
```

This makes reports and downstream analyses independent of backend-native object layouts.

---

# 11. `PredictionDistribution`: stable cross-paradigm contract

This class is central because it unifies:

- bootstrap predictive distributions;
- quantile regression;
- distributional regression;
- Gaussian processes;
- BART;
- Bayesian posterior predictive draws;
- MC dropout;
- deep ensembles;
- probabilistic neural-network heads;
- conformal wrappers where only interval/set operations are available.

Representative methods:

```r
smf_dist_mean()
smf_dist_median()
smf_dist_variance()
smf_dist_sd()
smf_dist_quantile()
smf_dist_interval()
smf_dist_sample()
smf_dist_log_prob()
smf_dist_cdf()
smf_dist_calibration()
```

Unavailable operations are capability-checked. A conformal interval, for example, must not pretend to expose a continuous density.

---

# 12. Typed uncertainty system

Create an `UncertaintyDescriptor` S7 class with fields equivalent to:

```text
source:
  analytical
  cross_validation
  bootstrap
  ensemble
  conformal
  approximate_bayesian
  bayesian_posterior

target:
  parameter
  metric
  prediction
  class_probability
  feature_importance
  ranking

interval_type:
  confidence
  credible
  prediction
  conformal
  resampling

level
conditional_on
```

Plotting and reporting functions must render labels from this descriptor. A credible interval can therefore never be accidentally reported as a confidence interval.

---

# 13. Capability registry

Every backend/model adapter declares a `CapabilitySet`, for example:

```text
regression
classification
multiclass
multioutput
sample_weight
case_weights
native_quantiles
native_distribution
posterior_sampling
variational_inference
bootstrap_wrapper
conformal_wrapper
gpu
multigpu
explain_shap
explain_gradient
checkpointing
safe_state_export
external_memory
```

Unsupported requests raise a structured `smf_capability_error` containing:

- requested operation;
- active family/engine;
- why the operation is unavailable;
- scientifically defensible alternatives.

No wrapper may convert a bootstrap distribution into a Bayesian posterior merely to satisfy an API request.

---

# 14. Recommended backend strategy

## 14.1 Core principle

`sciModelFlowR` owns scientific semantics. Existing packages remain computational engines.

## 14.2 Primary R modeling stack

Use the **tidymodels ecosystem** as the preferred classical workflow backend when it provides the required semantics:

- `recipes` for preprocessing and feature engineering;
- `rsample` for ordinary/grouped/temporal resampling;
- `spatialsample` for spatial resampling;
- `parsnip` for model specifications;
- `workflows` for preprocessing + model composition;
- `tune` for tuning;
- `yardstick` for common performance metrics;
- `themis` for imbalance handling inside recipes;
- `probably` for calibration and conformal regression tools;
- `workflowsets` and `stacks` where scientifically appropriate.

`sciModelFlowR` must wrap these packages rather than expose them as the scientific contract.

## 14.3 Advanced optimization and benchmark backend

Use **mlr3** as an optional advanced adapter when its capabilities are advantageous, particularly for:

- reusable Task/Learner/Resampling abstractions;
- nested resampling;
- advanced hyperparameter optimization;
- conditional search spaces;
- Bayesian optimization;
- Hyperband/successive halving;
- multi-objective optimization;
- benchmark archives;
- specialized extensions.

The public `sciModelFlowR` result schema must remain identical regardless of whether a workflow was executed through tidymodels or mlr3.

## 14.4 Classical engines

Initial candidates:

- `stats` / `glm`;
- `glmnet`;
- `ranger`;
- `kernlab`;
- `kknn`;
- `xgboost`;
- LightGBM R interface, certification-dependent;
- CatBoost R interface, certification-dependent;
- stacking/ensembles through validated adapters.

Backend availability must be versioned and certified. Optional engines may be quarantined without changing core specs.

---

# 15. Data audit and leakage prevention

The package must detect or flag:

- duplicate rows and IDs;
- exact/near-exact target copies;
- declared post-outcome variables;
- train/test overlap by row hash or entity ID;
- group leakage;
- pseudo-replication;
- preprocessing fitted globally before resampling;
- feature selection fitted outside resampling;
- oversampling performed before splitting;
- temporal look-ahead;
- spatial proximity leakage when spatial design is declared;
- external validation domains accidentally used in tuning.

Severity classes:

```text
detected
high-risk
possible
```

Warnings based only on variable names must remain heuristic warnings, never accusations of leakage.

---

# 16. Preprocessing subsystem

The preferred managed implementation is built around `recipes`, with package-owned guards and metadata.

Supported operations include:

- missing-value imputation;
- categorical encoding;
- normalization/standardization;
- transformations;
- winsorization when explicitly requested and scientifically justified;
- interaction generation;
- PCA and other unsupervised representations;
- domain-specific transforms;
- feature filtering;
- imbalance steps.

Every learned preprocessing object records:

- training partition hash;
- variables used;
- fitted statistics;
- outcome use, if any;
- fold ID;
- whether the operation is supervised;
- whether application to assessment/test data is allowed.

---

# 17. Resampling system

Required methods by 0.2.0:

- train/validation/test holdout;
- k-fold;
- repeated k-fold;
- stratified CV;
- grouped CV;
- blocked CV;
- nested CV;
- Monte Carlo CV;
- expanding-window time-series validation;
- sliding-window time-series validation;
- spatial block CV;
- spatial clustering CV;
- buffered spatial CV;
- leave-location-out CV;
- external validation.

Each split becomes a package-native immutable `SplitRecord` with:

- analysis indices;
- assessment indices;
- optional validation/test indices;
- group summaries;
- time bounds;
- spatial block IDs;
- source resampler;
- portable split hash.

## 17.1 Guard rules

Examples:

- repeated unit + ordinary random CV -> blocking error by default;
- time declared + shuffled random CV -> warning/error according to policy;
- coordinates declared + ordinary random CV -> high-severity warning requiring explicit override;
- nested tuning without inner resampling -> configuration error;
- external domain mixed into tuning -> error;
- globally prepped recipe in a managed resampling workflow -> error.

---

# 18. Cross-language split parity

Do **not** require Python and R RNGs to generate identical folds from the same integer seed.

For cross-language Gold tests:

1. generate and freeze neutral split manifests containing row IDs;
2. store them as JSON/CSV with SHA-256 hashes;
3. allow both implementations to ingest the same manifest;
4. compare model/scoring behavior on identical analysis/assessment sets.

This is scientifically stronger than treating different RNG implementations as a defect.

---

# 19. Bootstrap subsystem

Required schemes:

- case bootstrap;
- stratified bootstrap;
- residual bootstrap;
- parametric bootstrap;
- wild bootstrap;
- cluster bootstrap;
- hierarchical bootstrap;
- moving-block bootstrap;
- stationary block bootstrap;
- spatial-block bootstrap.

Targets:

- metric uncertainty;
- coefficient/statistic uncertainty;
- prediction uncertainty;
- feature-selection stability;
- hyperparameter-selection stability;
- model-ranking stability;
- explanation stability;
- calibration uncertainty.

Intervals:

- percentile;
- basic;
- BCa when valid;
- studentized when valid.

Every result records requested B, successful B, failures, sampling unit, interval method, seed strategy, original estimate, bias estimate where meaningful and convergence/stability versus B.

---

# 20. Feature selection and representation

Planned methods:

- near-zero variance;
- correlation/redundancy filters;
- collinearity/VIF diagnostics;
- mutual information;
- recursive feature elimination;
- sequential selection;
- L1/Elastic Net;
- tree-based selection;
- bootstrap selection frequency;
- stability selection;
- PCA;
- PLS;
- autoencoder representations;
- embeddings;
- interactions;
- domain-specific transformations.

Any fitted selector depending on outcomes or sample distribution must be fit inside resampling.

---

# 21. Supervised machine learning layer

Required families:

- ordinary linear models;
- regularized linear models;
- relevant generalized linear models;
- Random Forest;
- Extra Trees where a certified R engine is available;
- boosted trees;
- XGBoost;
- LightGBM where certified;
- CatBoost where certified;
- SVM;
- k-nearest neighbors;
- voting;
- stacking;
- explicit blending workflows.

The package must not pretend that all engines expose the same hyperparameters. Engine-specific parameters are namespaced inside `ModelSpec` and validated by the adapter.

---

# 22. Probabilistic machine learning

Supported output concepts:

- conditional means and variances;
- distribution parameters;
- conditional quantiles;
- expectiles when available;
- calibrated class probabilities;
- bootstrap predictive distributions;
- ensemble empirical distributions;
- conformal intervals/sets.

Planned response families where supported by a real likelihood/backend:

- Gaussian;
- Student-t;
- log-normal;
- Gamma;
- Beta;
- Poisson;
- negative binomial;
- Bernoulli;
- categorical;
- selected mixtures;
- quantile-only outputs.

Probabilistic metrics:

- negative log-likelihood;
- log score;
- CRPS;
- Brier score;
- interval score;
- weighted interval score;
- empirical coverage;
- interval width;
- calibration error;
- sharpness diagnostics;
- PIT diagnostics where justified.

Candidate supporting packages include `scoringRules`, `distributional`, `yardstick` extensions and package-native implementations validated against references.

---

# 23. Calibration and conformal prediction

## 23.1 Calibration

Support:

- logistic/Platt calibration;
- isotonic calibration;
- beta/multinomial calibration where supported;
- temperature scaling for neural networks;
- reliability diagrams;
- clearly defined expected calibration error;
- calibration validation using data not reused as final test data.

The `probably` package is a natural adapter for several calibration operations.

## 23.2 Conformal prediction

Initial R backend strategy:

- use `probably` for supported regression methods such as split/full/CV+/quantile conformal workflows;
- provide package-native wrappers for coverage diagnostics and uncertainty typing;
- add classification prediction sets only when a validated R backend or package-native implementation passes simulation coverage tests;
- dependence-aware time-series conformal methods remain gated until validated.

Conformal outputs must never be labeled Bayesian credible intervals or model-based confidence intervals.

---

# 24. Bayesian modeling layer

## 24.1 Preferred backend family

- `brms` as the preferred high-level Bayesian regression/multilevel/distributional adapter;
- Stan through `cmdstanr` when direct Stan execution is needed;
- `posterior` for posterior draws infrastructure;
- `bayesplot` for diagnostics/visualization where useful;
- `loo` for PSIS-LOO and related diagnostics;
- BART adapters such as `dbarts`/`BART`, selected through validation;
- Gaussian-process adapters selected by use case, with `brms` GP terms as a high-level validated route for appropriate scales.

## 24.2 Required Bayesian workflow contract

A Bayesian result is incomplete unless it records/exposes:

1. priors;
2. prior predictive behavior where feasible;
3. inference method;
4. chains/draws/warmup or approximation budget;
5. R-hat where meaningful;
6. bulk/tail ESS;
7. MCSE;
8. divergences and sampler diagnostics;
9. posterior summaries;
10. posterior predictive checks;
11. prior sensitivity when scientifically consequential;
12. predictive comparison such as PSIS-LOO when appropriate.

## 24.3 Initial Bayesian families

- Bayesian linear regression;
- logistic/binomial models;
- count models;
- hierarchical/multilevel models;
- robust/heavy-tailed regression;
- distributional models;
- BART regression/classification;
- Gaussian processes;
- selected multivariate models.

---

# 25. Deep Learning architecture

## 25.1 Primary engine

Use **`torch` for R** as the primary R-native Deep Learning engine.

`luz` can be an optional higher-level training adapter, but the public scientific API must not depend on luz objects.

`keras3` is an optional alternate adapter for users who require the Keras ecosystem.

## 25.2 Required training capabilities by 0.6.0

- epochs and minibatches;
- configurable optimizers;
- schedulers;
- early stopping;
- checkpointing;
- gradient clipping;
- mixed precision where supported;
- CPU/GPU device selection;
- deterministic-mode policy;
- training/validation histories;
- resume semantics;
- callbacks;
- manifest capture.

## 25.3 Architectures

- MLP;
- 1D/2D CNN;
- RNN;
- LSTM;
- GRU;
- TCN;
- Transformer;
- Vision Transformer where feasible;
- autoencoder;
- VAE;
- transfer learning;
- multimodal models;
- multitask models.

Each architecture declares supported modality/task in the capability registry.

---

# 26. Probabilistic and Bayesian Deep Learning

Production maturity order:

1. distributional output heads;
2. MC dropout;
3. deep ensembles;
4. Laplace approximation where a validated R implementation exists;
5. variational Bayesian neural networks implemented through validated `torch` modules;
6. full posterior sampling only for small architectures and expert workflows.

The package may implement a compact R-native variational BNN layer using `torch` distributions/autograd if no external R backend satisfies the scientific contract. Such functionality should begin as validation Tier 2 or Tier 3 until recovery and calibration simulations pass.

Aleatoric/epistemic decomposition is reported only when the fitted model and approximation actually identify the decomposition.

---

# 27. Hyperparameter optimization

The public tuning contract should support:

- grid search;
- random search;
- racing methods;
- successive halving;
- Hyperband;
- Bayesian/sequential optimization;
- conditional search spaces;
- pruning/early termination;
- multi-objective optimization;
- nested validation.

Backend strategy:

- `tune`/`finetune` for mainstream tidymodels workflows;
- `mlr3tuning`, `mlr3mbo`, `mlr3hyperband`, `paradox` and `bbotk` for advanced workflows.

Guards:

- test data cannot enter tuning;
- preprocessing and feature selection remain inside folds/trials;
- inner-CV scores are never presented as unbiased outer generalization performance;
- Pareto sets and compromise rules are stored;
- pruning decisions are logged;
- RNG policy and optimizer versions are recorded.

---

# 28. Metrics and scientific model comparison

## Regression

- RMSE;
- MAE;
- MSE;
- R-squared;
- RMSLE when valid;
- carefully defined percentage-error metrics;
- concordance correlation coefficient;
- domain-specific metrics through adapters.

## Classification

- accuracy;
- balanced accuracy;
- precision;
- recall/sensitivity;
- specificity;
- F1;
- MCC;
- Cohen's kappa;
- ROC-AUC;
- PR-AUC;
- log-loss;
- Brier score.

## Benchmark output

Include, as applicable:

- mean/fold distribution;
- interval estimate;
- external validation;
- calibration;
- stability;
- training time;
- prediction time;
- memory estimate;
- model size;
- hardware;
- DL parameter count;
- scientific warnings.

No default function may proclaim one universal winner from a single metric.

---

# 29. Class imbalance

Use fold-safe procedures only:

- case/class weights;
- random over/under-sampling;
- SMOTE and variants through `themis`;
- balanced ensembles where validated;
- threshold optimization;
- post-imbalance calibration;
- PR-AUC, MCC, balanced accuracy and class-specific error analysis.

A managed workflow must detect synthetic resampling performed before the training/assessment split.

---

# 30. Explainable AI

Support progressively:

- permutation importance;
- SHAP-compatible methods;
- PDP;
- ICE;
- ALE;
- local explanations;
- optional counterfactual explanations;
- interaction summaries;
- Integrated Gradients;
- saliency;
- Grad-CAM;
- attention visualization with explicit limitations.

Candidate R adapters include `DALEX`, `ingredients`, `iml`, `vip`, `fastshap`, tree-specific SHAP implementations and package-native torch gradient methods.

Every explanation result carries `causal_interpretation = FALSE` by default.

## 30.1 Explanation stability

Quantify variation across:

- CV folds;
- bootstrap resamples;
- model seeds;
- plausible preprocessing variants;
- correlated-feature perturbations.

The reporting layer must distinguish high importance from stable high importance.

---

# 31. Diagnostics

## Common

- leakage flags;
- train/validation distribution differences;
- fold stability;
- learning curves;
- validation curves;
- extrapolation/domain shift;
- high-error cases;
- uncertainty behavior.

## Regression

- observed versus predicted;
- residual versus fitted;
- residual distribution;
- heteroscedasticity patterns;
- residual autocorrelation for ordered designs;
- predictive interval coverage/width.

## Classification

- confusion matrix;
- ROC/PR;
- calibration;
- threshold curves;
- class-specific errors;
- imbalance-sensitive performance.

## Deep Learning

- training/validation loss;
- overfitting gap;
- learning-rate history;
- gradient norms when enabled;
- early-stopping reason;
- checkpoint history.

## Bayesian

- R-hat;
- bulk/tail ESS;
- MCSE;
- divergences;
- trace diagnostics;
- energy diagnostics where available;
- prior predictive checks;
- posterior predictive checks;
- PSIS-LOO diagnostics and Pareto-k flags.

---

# 32. Structured scientific warnings

Warnings are both R conditions and stored scientific records.

Proposed classes:

```text
smf_leakage_warning
smf_design_mismatch_warning
smf_pseudoreplication_warning
smf_resampling_warning
smf_calibration_warning
smf_convergence_warning
smf_posterior_warning
smf_uncertainty_warning
smf_explanation_warning
smf_extrapolation_warning
smf_reproducibility_warning
smf_serialization_security_warning
smf_backend_compatibility_warning
```

Each contains:

- severity: `info`, `warning`, `high`, `blocking`;
- evidence;
- suggested action;
- override status;
- originating module;
- run ID.

Overrides are written to the manifest.

---

# 33. Reproducibility and RNG policy

## 33.1 R RNG

Record:

- `.Random.seed` strategy;
- `RNGkind()`;
- top-level seed;
- parallel RNG strategy;
- independent DL ensemble seeds;
- backend-specific seeds.

Use `withr` for controlled RNG scopes. For reproducible parallel simulation, prefer documented L'Ecuyer-CMRG workflows where appropriate.

## 33.2 Hashing

Use SHA-256 for release and portable scientific artifacts.

Do not rely solely on serialized R object bytes for cross-version/cross-language hashes. Maintain:

- native R hash when useful;
- portable canonical hash from normalized JSON/CSV/Parquet metadata or neutral split manifests.

---

# 34. Run manifest

Every completed experiment emits JSON and YAML manifest forms containing at minimum:

```yaml
run_id: ...
created_at: ...
scimodelflowr_version: ...
r_version: ...
platform: ...
architecture: ...
core_dependency_versions: ...
optional_backend_versions: ...
cpu: ...
gpu: ...
rng_kind: ...
random_seed_policy: ...
determinism_policy: ...
data_hash_native: ...
data_hash_portable: ...
data_schema_hash: ...
experiment_spec_hash: ...
split_hashes: ...
preprocessing_hash: ...
feature_pipeline_hash: ...
model_spec: ...
hyperparameters: ...
metrics: ...
artifacts: ...
training_duration: ...
warnings: ...
```

---

# 35. Persistence and safe loading

Bundle structure:

```text
bundle/
├── manifest.json
├── spec.json
├── schema.json
├── preprocessing/
├── model/
├── labels.json
├── checksums.sha256
└── README.md
```

Rules:

- validate checksums before loading;
- validate schema/package/backend compatibility;
- treat opaque serialized objects from untrusted sources as unsafe;
- require explicit `trusted = TRUE` for unsafe loading paths;
- prefer portable metadata and backend-native state formats;
- record artifact provenance;
- support migrations for package schema versions;
- never promise ONNX equivalence for unsupported preprocessing/probabilistic semantics.

Optional integrations may include `pins`, `vetiver`, `mlflow` and backend-native export tools, but core persistence must work locally without them.

---

# 36. Reporting system

`smf_report()` generates a structured scientific report rather than a claim-generating narrative.

Required sections:

1. scientific question and target;
2. data and design declaration;
3. split/resampling strategy;
4. preprocessing and feature engineering;
5. candidate models/backends;
6. tuning protocol;
7. diagnostics;
8. point-performance metrics;
9. uncertainty/calibration/probabilistic metrics;
10. model comparison;
11. explanation and stability;
12. external validation;
13. computational information;
14. limitations and warnings;
15. reproducibility summary.

R gives an opportunity to support richer native outputs than the Python baseline:

- Markdown;
- HTML;
- Quarto;
- PDF where toolchain is available;
- DOCX through Quarto/R Markdown;
- LaTeX;
- CSV;
- Parquet when `arrow` is available;
- publication tables through `gt`/`flextable` adapters.

Heavy reporting packages remain optional.

---

# 37. Scientific plotting standards

Plots must:

- show observed data where feasible;
- display uncertainty;
- label the interval type;
- avoid isolated bar charts for continuous outcomes when distributions can be shown;
- use non-distorting scales;
- distinguish observed, fitted, conditional, marginal and predictive quantities;
- support vector export for line/text graphics;
- support high-resolution raster output for image-heavy figures;
- use accessible palettes;
- remain interpretable in grayscale where practical.

Primary plotting backend should be `ggplot2`, returning editable ggplot objects whenever possible.

---

# 38. Gold datasets

Reuse the same scientific scenarios as the Python package wherever possible:

- `gold_linear_regression`
- `gold_heteroscedastic_regression`
- `gold_binary_calibration`
- `gold_multiclass_imbalanced`
- `gold_grouped_fields`
- `gold_hierarchical_yield`
- `gold_time_climate`
- `gold_spatial_soil`
- `gold_spectral_curve`
- `gold_hyperspectral_small`
- `gold_rgb_leaf_small`
- `gold_multimodal_stress`
- `gold_count_pests`
- `gold_nonlinear_bart`
- `gold_gp_surface`
- `gold_distributional_yield`
- `gold_covariate_shift`
- `gold_missingness_mcar_mar`
- `gold_conformal_heteroscedastic`
- `gold_dl_tiny`

Each dataset card records scientific scenario, generator, units, seed, dimensions, dependence, known parameters, expected recovery, tolerances, pedagogical traps, license/provenance and SHA-256 hash.

Simulated datasets are always explicitly labeled as simulated and never presented as field evidence.

---

# 39. Cross-language Gold validation

A dedicated `inst/crosslang/` layer should contain neutral fixtures:

```text
inst/crosslang/
├── schemas/
├── datasets/
├── split_manifests/
├── expected_metrics/
├── expected_predictions/
├── tolerances.yml
└── algorithm_versions.yml
```

Cross-language tests should compare:

- preprocessing semantics;
- split membership from shared manifests;
- common metrics;
- deterministic baseline models where algorithms match;
- probability normalization;
- interval ordering;
- calibration summaries;
- bootstrap statistics under shared sampled indices where appropriate;
- manifest schema compatibility.

Differences caused by distinct backend algorithms must be documented rather than forced into false numerical equality.

---

# 40. Testing architecture

Use `testthat` as the primary unit/integration framework.

Test layers:

```text
tests/testthat/
  unit/
  integration/
  numerical/
  regression/
  golden/
  property/
  determinism/
  cpu-gpu/
  serialization/
  pipelines/
  reports/
  notebooks/
  cross-language/
```

## 40.1 Numerical tests

Validate against:

- analytical expectations;
- R backend-native implementations;
- the Python package where scientific equivalence is defined;
- trusted independent packages;
- frozen simulations.

## 40.2 Golden tests

Freeze deterministic numerical/tabular artifacts, not screenshots as a substitute for science.

## 40.3 Property/invariant tests

Verify properties such as:

- analysis/assessment disjointness;
- no group splitting when forbidden;
- forward-only temporal training;
- probability sums equal one within tolerance;
- interval lower <= upper;
- quantile monotonicity when guaranteed;
- round-trip bundle prediction equivalence;
- deterministic pathway reproducibility.

A property-based testing package may be added if maintained and useful, but critical invariants must not depend on it.

## 40.4 Plot regression

Use `vdiffr` only for appropriate visual regressions. Numerical truth is tested separately.

## 40.5 Simulation tests

Release-candidate simulation batteries should assess:

- bootstrap coverage;
- conformal marginal coverage;
- Bayesian parameter recovery;
- probability calibration;
- pathological MCMC detection;
- nested-CV optimism prevention;
- time/spatial leakage prevention;
- BNN/probabilistic-DL calibration where supported.

---

# 41. Validation tiers

Every engine/method has a tier.

## Tier 1: fully validated

- automatic workflow eligible;
- unit tests;
- numerical tests;
- examples;
- documentation;
- diagnostics;
- simulation validation when required.

## Tier 2: advanced validated

- supported and tested;
- explicit user selection;
- not automatically chosen.

## Tier 3: expert/experimental

- backend-accessible or experimental;
- explicit opt-in;
- package does not claim complete validation.

This is particularly important for specialized Bayesian families, rare engines, BNNs and experimental GPU features.

---

# 42. Proposed package tree

```text
sciModelFlowR/
├── DESCRIPTION
├── NAMESPACE
├── LICENSE
├── NEWS.md
├── README.md
├── CITATION.cff
├── inst/CITATION
├── R/
│   ├── core-classes.R
│   ├── core-generics.R
│   ├── core-validation.R
│   ├── core-capabilities.R
│   ├── core-warnings.R
│   ├── core-provenance.R
│   ├── core-randomness.R
│   ├── spec-data.R
│   ├── spec-task.R
│   ├── spec-design.R
│   ├── spec-preprocess.R
│   ├── spec-feature.R
│   ├── spec-resampling.R
│   ├── spec-bootstrap.R
│   ├── spec-model.R
│   ├── spec-probabilistic.R
│   ├── spec-bayesian.R
│   ├── spec-dl.R
│   ├── spec-tuning.R
│   ├── spec-uncertainty.R
│   ├── spec-explain.R
│   ├── spec-benchmark.R
│   ├── spec-reporting.R
│   ├── spec-experiment.R
│   ├── data-audit.R
│   ├── data-missing.R
│   ├── data-outliers.R
│   ├── data-leakage.R
│   ├── design-validate.R
│   ├── design-hierarchy.R
│   ├── design-temporal.R
│   ├── design-spatial.R
│   ├── preprocess-recipes.R
│   ├── resampling-core.R
│   ├── resampling-temporal.R
│   ├── resampling-spatial.R
│   ├── resampling-nested.R
│   ├── bootstrap-core.R
│   ├── bootstrap-dependent.R
│   ├── features-core.R
│   ├── features-stability.R
│   ├── model-registry.R
│   ├── adapter-tidymodels.R
│   ├── adapter-mlr3.R
│   ├── adapter-xgboost.R
│   ├── adapter-lightgbm.R
│   ├── adapter-catboost.R
│   ├── probabilistic-core.R
│   ├── probabilistic-scoring.R
│   ├── calibration.R
│   ├── conformal.R
│   ├── bayes-brms.R
│   ├── bayes-bart.R
│   ├── bayes-gp.R
│   ├── bayes-diagnostics.R
│   ├── dl-torch.R
│   ├── dl-luz.R
│   ├── dl-keras3.R
│   ├── dl-models.R
│   ├── dl-probabilistic.R
│   ├── dl-xai.R
│   ├── tuning.R
│   ├── metrics.R
│   ├── imbalance.R
│   ├── uncertainty.R
│   ├── diagnostics.R
│   ├── explain.R
│   ├── benchmark.R
│   ├── experiment.R
│   ├── tracking.R
│   ├── persistence.R
│   ├── plotting.R
│   ├── reporting.R
│   ├── datasets.R
│   ├── validation-gold.R
│   ├── validation-reference.R
│   └── doctor.R
├── man/
├── data/
├── data-raw/
├── tests/testthat/
├── vignettes/
├── inst/
│   ├── schema/
│   ├── gold/
│   ├── crosslang/
│   ├── metadata/
│   ├── templates/
│   └── extdata/
├── references/
├── pkgdown/
├── tools/
├── renv.lock
├── _pkgdown.yml
├── .Rbuildignore
└── .github/workflows/
```

No `src/` compiled-code directory is required initially. Add compiled code only after profiling demonstrates a justified need.

---

# 43. Dependency policy

## 43.1 Small core

Candidate core Imports should remain modest, for example:

- `S7`;
- `rlang`;
- `vctrs`;
- `tibble`;
- `cli`;
- `digest`;
- `jsonlite`;
- `withr`.

Exact minimum versions must be fixed by the 0.1.0 compatibility matrix, not guessed in advance.

## 43.2 Modeling packages

Prefer individual packages in `Suggests` rather than importing the entire `tidymodels` metapackage.

Candidate optional groups conceptually include:

```text
modeling: recipes, rsample, parsnip, workflows, yardstick
spatial: spatialsample, sf
tuning: tune, finetune, mlr3, mlr3tuning, mlr3mbo, mlr3hyperband
imbalance: themis
probabilistic: probably, scoringRules, distributional
bayes: brms, cmdstanr, posterior, bayesplot, loo
bart_gp: validated BART/GP backends
dl: torch, luz
dl_alt: keras3
xai: DALEX, ingredients, iml, vip, fastshap
reporting: ggplot2, gt, flextable, quarto, rmarkdown
tracking: mlflow, pins, vetiver
large_data: arrow, duckdb
```

Optional functionality fails with informative installation guidance, never by silently falling back to a scientifically different method.

## 43.3 Reproducible environments

Use:

- `renv` for frozen project environments;
- `pak` for dependency resolution/installation;
- lockfiles for release validation and documentation builds;
- explicit Windows local-validation instructions.

---

# 44. R support policy and CI

Do not hard-code an unnecessarily narrow minimum R version before compatibility testing.

Initial policy:

- support R release, oldrel and devel where dependencies permit;
- test Windows, Ubuntu and macOS for core;
- CPU-only core checks must never require a GPU;
- GPU tests run on dedicated runners or local validation;
- heavy Bayesian/DL tests are tiered and may run nightly/release-candidate rather than on every commit.

CI gates:

```text
R CMD check
unit tests
integration tests
numerical/Gold tests
coverage
pkgdown build
vignette/Quarto render
installation smoke test
minimum/recent dependency profile
```

---

# 45. Documentation architecture

## 45.1 Canonical instructional format

For R, replace the Python-specific Jupyter+marimo pairing with an R-native dual strategy:

1. **canonical Quarto `.qmd` vignette/tutorial**;
2. **paired Jupyter `.ipynb` with IRkernel** for users who work in Jupyter.

Both share a neutral YAML lesson contract containing learning objectives, datasets, expected warnings, seed policy and key numerical assertions.

Marimo is not ported because it is Python-specific; semantic parity is preserved through Quarto + IRkernel, not by forcing an unsuitable tool into R.

## 45.2 Global tutorial

Target a foundations-to-advanced tutorial of approximately 8,500-10,000 words, synchronized with the 1.0 API.

Recommended file:

`v01-foundations-to-advanced-scientific-modeling.qmd`

Progression:

1. scientific question and unit of analysis;
2. data roles;
3. audit and leakage;
4. leakage-safe preprocessing;
5. random/grouped/temporal/spatial/external validation;
6. baseline ML;
7. feature selection inside resampling;
8. nested tuning;
9. bootstrap;
10. probabilistic prediction;
11. calibration and conformal prediction;
12. XAI and stability;
13. deterministic DL;
14. probabilistic DL;
15. Bayesian foundations;
16. BART/GP;
17. Bayesian DL when justified;
18. benchmarking and decision rules;
19. persistence/tracking;
20. agronomic workflow;
21. spectroscopy/remote sensing workflow;
22. time/spatial workflow;
23. common mistakes;
24. publication checklist;
25. API/capability map.

Focused substantial vignettes should generally be about 60-70% of the central tutorial length when the topic requires a full workflow.

## 45.3 Focused vignettes

Recommended sequence:

```text
v00-overview.qmd
v01-foundations-to-advanced-scientific-modeling.qmd
v02-data-audit-and-leakage.qmd
v03-resampling-and-scientific-design.qmd
v04-bootstrap-and-stability.qmd
v05-feature-engineering-and-selection.qmd
v06-supervised-machine-learning.qmd
v07-probabilistic-machine-learning.qmd
v08-tuning-and-nested-validation.qmd
v09-imbalance-calibration-and-thresholds.qmd
v10-explainable-ai-and-stability.qmd
v11-deep-learning-foundations.qmd
v12-cnn-and-vision-workflows.qmd
v13-temporal-models-and-transformers.qmd
v14-probabilistic-deep-learning.qmd
v15-bayesian-foundations.qmd
v16-bart-and-gaussian-processes.qmd
v17-bayesian-deep-learning.qmd
v18-conformal-prediction.qmd
v19-benchmarking-and-model-comparison.qmd
v20-tracking-persistence-and-reproducibility.qmd
v21-agronomy-and-soil-workflows.qmd
v22-spectroscopy-and-hyperspectral-workflows.qmd
v23-spatial-environmental-and-climate-workflows.qmd
v24-complete-scientific-workflow.qmd
v25-api-example-catalog.qmd
v26-state-of-the-art-and-rationale.qmd
v27-validation-and-reproducibility.qmd
```

Every focused scientific vignette should include at least one Gold dataset and one scientifically inappropriate workflow with explanation of why it fails.

---

# 46. Documentation contract for every exported function

Every exported analytical function should have:

- purpose;
- arguments;
- return class;
- assumptions;
- failure conditions;
- uncertainty semantics;
- references where relevant;
- related functions;
- minimum example;
- realistic agronomic/environmental example;
- advanced or discrepant-case example.

Roxygen2 documentation is authoritative for the API reference.

---

# 47. State-of-the-art artifact

Maintain a dedicated vignette and machine-readable reference ledger that cover:

- problem definition;
- competing R/Python software ecosystems;
- capabilities;
- gaps;
- package contribution;
- limitations;
- update date;
- references with metadata verification.

Recommended files:

```text
vignettes/v26-state-of-the-art-and-rationale.qmd
inst/metadata/reference_verification.csv
inst/METADATA_VERIFICATION.md
vignettes/references.bib
references/package_references.ris
```

This artifact later supports the software-paper Introduction, Related Software and Discussion sections.

---

# 48. Scientific reference policy

- verify methodological references against at least two metadata sources when practical;
- verify DOI against publisher/indexing metadata when a DOI exists;
- never invent DOI, pages, issue or authors;
- distinguish software citations from methodological claims;
- record access dates for version-sensitive software documentation;
- generate RIS/BibTeX companions;
- check citation-reference consistency before release.

---

# 49. Version roadmap

## 0.1.0: Foundations, data, design and API contracts

Deliverables:

- package skeleton;
- S7 specs and result base classes;
- capability registry;
- data/schema/missingness audit;
- leakage-screen framework;
- design declarations;
- split records;
- reproducibility manifest;
- at least six Gold datasets;
- `smf_doctor()` and capability report;
- initial plotting/report skeleton;
- global tutorial initial sections;
- Quarto + IRkernel quick-start lesson.

Acceptance gates:

- no managed preprocessing can be fit to test data;
- group/time/space declarations survive serialization;
- deterministic split manifests reproduce within R;
- core contract test coverage target >= 90%;
- public S7 specs round-trip through portable schemas;
- optional ML/DL/Bayes backends are not loaded on core import;
- `R CMD check` core path passes in validated environment.

## 0.2.0: Resampling, bootstrap and feature engineering

Deliverables:

- grouped, blocked, nested, temporal, spatial, external and Monte Carlo resampling;
- bootstrap family;
- feature filters/RFE/sequential/regularized/tree/PCA/PLS/stability methods;
- fold-safe selector execution;
- focused vignettes 02-05.

Acceptance:

- groups never cross forbidden folds;
- time validation never trains on future data by default;
- spatial blocks reproducible from configuration;
- IID bootstrap on declared dependent design blocks/warns appropriately;
- simulation coverage tests pass predefined bands;
- feature selection outside resampling is detected.

## 0.3.0: Supervised ML and probabilistic foundation

Deliverables:

- tidymodels adapters;
- initial mlr3 adapters;
- regression/classification/multi-output where supported;
- xgboost and certified optional boosting engines;
- fold-safe imbalance handling;
- stable `PredictionDistribution`;
- calibration;
- initial probabilistic scoring;
- vignettes 06, 07 and 09.

Acceptance:

- adapter predictions match direct backend predictions within tolerance;
- unsupported density operations remain unavailable;
- calibration excludes final test labels;
- imbalance operations occur only on analysis folds;
- class-probability rows sum to one within tolerance.

## 0.4.0: Tuning and scientific benchmarking

Deliverables:

- grid/random search;
- racing;
- Bayesian optimization;
- successive halving/Hyperband;
- multi-objective optimization;
- nested CV;
- benchmark decision rules;
- vignettes 08 and 19.

Acceptance:

- test data cannot enter managed tuning;
- inner/outer split hashes differ and are recorded;
- selection and outer-generalization estimates are labeled separately;
- Pareto set and compromise rule are stored;
- no default universal single-metric winner.

## 0.5.0: Explainability and explanation stability

Deliverables:

- permutation importance;
- SHAP adapter(s);
- PDP/ICE/ALE;
- local explanations;
- optional counterfactuals;
- stability across folds/bootstrap/seeds;
- correlated-feature warnings;
- vignette 10.

Acceptance:

- transformed features trace to source features when mapping exists;
- XAI output marked non-causal;
- stability metrics reproduce on Gold fixtures;
- plots preserve sign/direction semantics.

## 0.6.0: Deep Learning and probabilistic DL

Deliverables:

- torch trainer;
- optional luz adapter;
- MLP/CNN/RNN/LSTM/GRU/TCN/Transformer/ViT/AE/VAE;
- transfer learning;
- multimodal/multitask interfaces;
- early stopping/checkpoints/schedulers/mixed precision;
- MC dropout;
- deep ensembles;
- distributional heads;
- gradient-based XAI;
- optional keras3 adapter;
- vignettes 11-14.

Acceptance:

- CPU smoke suite passes without CUDA;
- GPU suite uses numerical tolerance;
- checkpoint reload reproduces predictions within tolerance;
- determinism level is declared;
- probabilistic head constraints validated;
- ensemble seeds independently recorded;
- unsafe checkpoint loading is not default.

## 0.7.0: Bayesian modeling, conformal prediction and full uncertainty

Deliverables:

- brms/Stan adapter;
- posterior/loo integration;
- BART adapter;
- GP adapter;
- prior and prior-predictive workflows;
- convergence diagnostics;
- posterior predictive checks;
- PSIS-LOO;
- conformal adapters;
- uncertainty decomposition where identifiable;
- vignettes 15-18.

Acceptance:

- Gold simulations recover parameters within preregistered bands;
- pathological MCMC triggers warnings;
- approximation method is explicit;
- conformal simulation achieves target marginal coverage within tolerance;
- credible and conformal intervals render differently;
- no false epistemic/aleatoric decomposition.

## 0.8.0: Tracking, persistence, deployment and scalability

Deliverables:

- local tracker;
- optional MLflow/pins/vetiver adapters;
- inference bundles;
- compatibility checks;
- safe loading policy;
- batch prediction;
- resume semantics;
- optional compatible deployment/export adapters;
- large-data iterator interfaces where feasible;
- vignette 20.

Acceptance:

- corrupted checksums rejected;
- incompatible major schema rejected with migration guidance;
- unsafe loading requires explicit trust;
- preprocessing+model reload reproduces predictions;
- manifest records hardware and backend versions;
- optional tracker absence never blocks local runs.

## 0.9.0: Integrated scientific release candidate

Deliverables:

- cross-module workflows;
- external validation;
- domain vignettes 21-24;
- API catalog;
- full Gold suite;
- Quarto/Jupyter paired curriculum;
- publication tables/plots/reporting;
- R↔Python differential tests;
- migration/deprecation docs;
- release candidate API freeze.

Acceptance:

- all exports documented;
- vignettes satisfy instructional contracts;
- notebooks/tutorials execute in clean validated environments;
- no critical Gold/numerical/reference failure;
- optional backends are validated or explicitly quarantined;
- no release TODO/placeholders;
- citation/reference consistency check passes.

## 1.0.0: Consolidated Scientific Release

Deliverables:

- stable 1.x public contracts;
- CRAN source package artifact when release checks permit;
- source snapshot ZIP/TAR.GZ;
- final compatibility matrix;
- final security review;
- complete pkgdown site;
- vignettes/notebooks/data cards/API docs;
- verified bibliography;
- benchmark baselines;
- release notes/migration guide;
- archived Gold hashes and release manifest.

Acceptance:

- no known critical scientific/security blocker;
- clean install and smoke tests on supported R environments;
- numerical/Gold suite passes under frozen release environments;
- API changes since 0.9.0 limited to blocker corrections;
- deprecation policy documented;
- hashes verified;
- central tutorial synchronized with 1.0.0 API;
- `R CMD check --as-cran` status explicitly reported rather than inferred.

---

# 50. CRAN and release engineering

Every release candidate should produce:

- source snapshot;
- `R CMD build` tarball after actual build;
- SHA-256 checksums;
- dependency/compatibility report;
- Gold hashes;
- API diff;
- documentation build report;
- vignette/notebook execution report;
- benchmark regression summary;
- security/advisory audit summary;
- provenance manifest.

Never label an unexecuted static source snapshot as “CRAN-ready”.

Final gate:

```bash
R CMD build sciModelFlowR
R CMD check --as-cran sciModelFlowR_<version>.tar.gz
```

plus testthat, Gold/numerical tests, vignettes and pkgdown.

---

# 51. Release-blocking scientific defects

The following block release:

- managed-pipeline leakage;
- final test data used in tuning;
- group/spatial/temporal split violating declared design;
- materially incorrect metric formula;
- incorrect uncertainty/interval label;
- Bayesian convergence failure hidden from results;
- invalid conformal guarantee;
- probabilistic score evaluated on wrong scale/distribution;
- Gold generator/hash mismatch;
- unsafe untrusted serialization loaded without explicit trust;
- tutorial teaching a workflow that violates package safeguards;
- fabricated or unresolved citation metadata in release documentation;
- R/Python parity claim without an actual differential test where parity is asserted.

---

# 52. Scientific domain workflows

## Agronomy

- yield prediction with site/season grouping;
- nitrogen response and external-environment prediction;
- nested experimental sampling;
- uncertainty-aware decision thresholds.

## Soil Science

- pedotransfer functions;
- spatial CV;
- uncertainty maps;
- covariate shift between regions.

## Spectroscopy

- Vis-NIR/NIR/SWIR predictors;
- wavelength-selection stability;
- PLS baseline versus nonlinear models;
- 1D CNN;
- probabilistic predictions.

## Remote sensing and phenotyping

- RGB/multispectral classification/regression;
- transfer learning;
- Grad-CAM with stability caveats;
- spatially separated validation.

## Plant physiology/stress

- multimodal tabular + image workflows;
- multitask prediction;
- calibrated stress probabilities;
- uncertainty under domain shift.

## Climate/environmental series

- time-aware validation;
- block bootstrap;
- sequence models;
- probabilistic forecasts;
- nonstationarity/shift diagnostics.

---

# 53. Minimum scientific reporting checklist

Before a result leaves a notebook, thesis, report or manuscript, document:

- [ ] scientific target;
- [ ] unit of analysis;
- [ ] grouping/block/hierarchy/repeated unit/time/space;
- [ ] train/validation/test or external validation;
- [ ] preprocessing learned only on training partitions;
- [ ] feature selection relative to resampling;
- [ ] model and backend version;
- [ ] hyperparameter optimization protocol;
- [ ] metric definitions/aggregation;
- [ ] calibration/threshold rule for probabilistic classification;
- [ ] uncertainty method and interval/set type;
- [ ] bootstrap unit and B if applicable;
- [ ] priors and prior-predictive rationale for Bayesian models;
- [ ] convergence and posterior predictive diagnostics;
- [ ] conformal calibration source and target coverage;
- [ ] observed data with estimates where feasible;
- [ ] explanation method and stability;
- [ ] external validation or limitation;
- [ ] seeds/RNG/package versions/data hash/split hash;
- [ ] warnings and overrides;
- [ ] extrapolation and causal limitations.

---

# 54. Cross-language interoperability contract

The R and Python packages should share a neutral schema family for:

- experiment specs;
- design declarations;
- split manifests;
- warning records;
- uncertainty descriptors;
- dataset cards;
- run manifests;
- selected result tables.

Recommended portable formats:

- JSON for structured specs/manifests;
- YAML for human-readable lessons/configurations;
- CSV/Parquet for tabular outputs;
- SHA-256 checksums;
- schema/algorithm version fields.

This permits a future workflow in which an experiment specification created in R can be audited or re-executed in Python when an equivalent backend exists, and vice versa.

---

# 55. Important differences from the Python package

The R package should intentionally differ in the following ways:

1. **S7 instead of Python dataclasses/protocols** for formal package-native contracts.
2. **tidymodels as the preferred classical workflow backend**, with mlr3 optional for capabilities where it is stronger.
3. **Quarto + IRkernel** instead of Jupyter + marimo.
4. **torch for R** as primary DL engine, with luz/keras3 optional.
5. **brms/Stan** as the preferred high-level Bayesian interface.
6. **R conditions** as structured warnings/errors in addition to persistent warning records.
7. **pkgdown/Roxygen2** for API documentation.
8. **renv + pak** for reproducible R environments.
9. **R CMD check/CRAN gates** instead of wheel/sdist/PyPI gates.
10. **Cross-language split manifests** rather than expecting identical RNG streams.

These are architectural adaptations, not losses of scientific functionality.

---

# 56. Recommended implementation order inside every version

1. update specification delta and ADRs;
2. confirm active backend/dependency constraints;
3. implement package-native S7 contracts first;
4. implement backend adapters behind those contracts;
5. add Gold/reference fixtures before broad examples;
6. add unit and numerical tests;
7. add integration/invariant tests;
8. add Quarto/Jupyter paired lessons;
9. extend vignettes;
10. run clean-environment validation;
11. freeze hashes/manifests;
12. update R↔Python parity ledger;
13. produce release notes and compatibility matrix.

---

# 57. Quality gates

```text
GATE 1   Scientific scope explicit
GATE 2   R ecosystem/backends reviewed
GATE 3   Architecture defined
GATE 4   Public API documented
GATE 5   Core implementation complete
GATE 6   Numerical/statistical validation added
GATE 7   Tests added
GATE 8   Tutorials/vignettes complete
GATE 9   State-of-the-art artifact complete
GATE 10  Dependency/reproducibility strategy documented
GATE 11  Cross-language parity status documented
GATE 12  Runtime release checks executed or explicitly pending
GATE 13  Release artifacts reproducible
GATE 14  Final scientific/security audit performed
```

For `sciModelFlowR`, add subgates for:

- R release/oldrel/devel;
- Windows/macOS/Linux;
- CPU/GPU distinction;
- backend certification tier;
- portable manifest/schema version;
- R↔Python differential validation.

---

# 58. Current R ecosystem baseline informing the proposal

The architecture is consistent with the current R ecosystem as checked for this proposal:

- tidymodels provides integrated recipes, resampling, workflows, tuning and metrics;
- `spatialsample` provides spatial clustering, block, buffered and leave-location-out resampling;
- `probably` provides calibration tools and several regression conformal methods including CV+;
- mlr3 provides Task/Learner/Resampling/Prediction/Benchmark abstractions, while mlr3tuning supports nested and multi-objective optimization and extensions for Bayesian optimization and Hyperband;
- `torch` remains an R-native PyTorch-based DL framework, with `luz` as a higher-level training layer;
- `keras3` remains an alternative R interface for the Keras ecosystem;
- `brms` provides Bayesian generalized multivariate nonlinear and multilevel modeling through Stan;
- `loo` provides PSIS-LOO diagnostics/model comparison infrastructure;
- S7 provides formal classes, validators and compatibility with S3/S4.

Exact package minimum versions must be fixed only after the first compatibility matrix and should not be copied from a transient web snapshot into stable contracts.

---

# 59. Final recommendation

Proceed with `sciModelFlowR` as a **scientifically equivalent R implementation** of the Python architecture, but make the R package genuinely native to its ecosystem.

The most important design decision is to freeze, already in 0.1.0, the shared grammar connecting:

```text
scientific question
→ design declaration
→ data audit
→ leakage-safe preprocessing
→ design-aware resampling
→ baseline model
→ tuning inside resampling
→ diagnostics
→ typed uncertainty / calibration
→ explanation + stability
→ external validation
→ scientific communication
→ reproducibility manifest
```

The second most important decision is to make `ExperimentSpec`, `PredictionDistribution`, `UncertaintyDescriptor`, `CapabilitySet`, structured scientific warnings and `RunManifest` stable contracts shared conceptually with the Python package.

The third is to treat R and Python as **paired scientific implementations**, validated through shared Gold datasets and neutral split/result fixtures. This creates more value than maintaining two packages that merely have similar names.

---

# 60. Immediate next implementation task

The recommended next step is **version 0.1.0**, not additional architectural expansion.

Version 0.1.0 should first create:

- DESCRIPTION/NAMESPACE/package skeleton;
- S7 core specs;
- result base classes;
- capability registry;
- warning/condition framework;
- data/design audit;
- leakage guards;
- reproducibility/hash system;
- six initial Gold datasets;
- roxygen2 docs;
- tests for contracts;
- `v00-overview.qmd` and initial `v01-foundations-to-advanced-scientific-modeling.qmd` sections;
- `smf_doctor()`;
- R↔Python shared-schema prototype.

Only after those contracts pass their acceptance gates should 0.2.0 add the full resampling/bootstrap/feature-engineering engines.

---

# Appendix A. Proposed backend capability matrix

Legend: **N** native/preferred, **W** wrapper, **A** alternate, **E** experimental, blank = not a target capability.

| R backend/ecosystem | Main role | Reg/Class | Probabilistic | Bayesian | Bootstrap | Conformal | GPU | XAI | Tuning | Proposed status |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| tidymodels | classical workflow | N | partial/W |  | W | W | engine-dependent | W | N | Primary classical |
| mlr3 | advanced ML orchestration | N | partial | extension | W | extension | engine-dependent | W | N | Advanced optional |
| xgboost R | boosting | N | partial |  | W | W | N | N/W | W | Stable optional |
| LightGBM R | boosting | N | partial |  | W | W | N | N/W | W | Certification-dependent |
| CatBoost R | boosting/categorical | N | partial |  | W | W | N | N/W | W | Certification-dependent |
| probably | calibration/conformal |  | W |  |  | N regression |  |  |  | Stable adapter |
| brms/Stan | Bayesian models | N | N | N | W | W | backend-dependent | W | limited | Primary Bayes |
| BART backend | Bayesian trees | N | N | N | W | W | backend-dependent | W | limited | Stable optional after certification |
| GP backend | Gaussian processes | N | N | N/approx | W | W | backend-dependent | W | limited | Capability-tiered |
| torch | Deep Learning | N | N via heads | custom/approx | W | W | N | N/W | W | Primary DL |
| luz | training abstraction | via torch | via torch | via torch | W | W | N | W | W | Optional trainer |
| keras3 | alternate DL | N | N | backend-dependent | W | W | N | W | W | Alternate adapter |
| DALEX/ingredients/iml/etc. | explanation |  |  |  |  |  |  | N |  | Optional XAI |
| mlflow/pins/vetiver | tracking/deployment |  |  |  |  |  |  |  |  | Optional |

---

# Appendix B. Proposed public function map

| Area | Representative API |
|---|---|
| Data | `smf_audit_data()`, `smf_validate_schema()`, `smf_missingness_report()`, `smf_detect_leakage()` |
| Design | `smf_validate_design()`, `smf_design_summary()`, `smf_check_pseudoreplication()` |
| Preprocessing | `smf_build_preprocessor()`, `smf_transform_with_provenance()` |
| Resampling | `smf_make_resampler()`, `smf_make_nested_resampler()`, `smf_split_manifest()` |
| Bootstrap | `smf_bootstrap()`, `smf_bootstrap_interval()`, `smf_bootstrap_stability()` |
| Features | `smf_select_features()`, `smf_feature_stability()`, `smf_build_representation()` |
| Models | `smf_register_model()`, `smf_fit_experiment()`, `predict()` |
| Probabilistic | `smf_predict_distribution()`, `smf_score_distribution()` |
| Calibration | `smf_calibrate()`, `smf_calibration_report()` |
| Conformal | `smf_conformalize()`, `smf_coverage_report()` |
| Bayesian | `smf_prior_predictive()`, `smf_fit_bayesian()`, `smf_posterior_predictive()`, `smf_posterior_diagnostics()` |
| DL | `smf_fit_deep_model()`, `smf_training_history()`, `smf_load_checkpoint()` |
| Tuning | `smf_tune()`, `smf_pareto_front()`, `smf_tuning_report()` |
| Metrics | `smf_evaluate()`, `smf_evaluate_probabilistic()` |
| XAI | `smf_explain()`, `smf_explanation_stability()` |
| Diagnostics | `smf_diagnose()`, `smf_shift_diagnostics()`, `smf_error_analysis()` |
| Benchmark | `smf_benchmark()`, `smf_compare_models()`, `smf_decision_table()` |
| Tracking | `smf_start_run()`, `smf_log_result()`, `smf_end_run()` |
| Reporting | `smf_table()`, `smf_plot()`, `smf_report()` |
| Persistence | `smf_save_bundle()`, `smf_load_bundle()`, `smf_validate_bundle()` |
| Datasets | `smf_load_dataset()`, `smf_dataset_card()`, `smf_list_datasets()` |
| Validation | `smf_run_gold_validation()`, `smf_run_reference_validation()`, `smf_run_crosslang_validation()` |
| System | `smf_doctor()`, `smf_capabilities()` |

---

# Appendix C. Proposed backend certification record

```yaml
backend: xgboost
adapter_version: 1
validation_tier: 1
validated_versions:
  minimum: ...
  tested: [...]
r_versions: [...]
platforms: [windows, linux, macos]
cpu: true
gpu:
  status: tested-optional
capabilities: ...
known_limitations: ...
security_notes: ...
last_validated: ...
reference_tests: ...
cross_language_tests: ...
```

A backend may be temporarily marked `quarantined` without changing the core `ExperimentSpec` or result schemas.

---

# Appendix D. Recommended 0.1.0 ADRs

Create Architecture Decision Records for at least:

1. package naming and R/Python family identity;
2. S7 use for core contracts;
3. tidymodels as preferred classical backend;
4. mlr3 as advanced optional backend;
5. torch as primary R-native DL backend;
6. brms/Stan Bayesian strategy;
7. Quarto + IRkernel teaching parity;
8. portable JSON/YAML schemas;
9. RNG/split-manifest cross-language strategy;
10. persistence/security policy;
11. validation tiers;
12. versioned backend certification.

---

# End of proposal
