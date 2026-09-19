# sciModelFlowR Migration Guide: 0.1.0 to 0.9.0

# 1. Purpose

This guide explains how the public scientific grammar evolved from 0.1.0
to the 0.9.0 release candidate and how users should update analyses
without losing design, leakage, uncertainty, or provenance semantics.
The package is intentionally cumulative: later versions add layers
around stable core contracts rather than replacing the central idea that
design precedes modeling and training-only learning precedes assessment.

Version 0.9.0 is the API-freeze point for 1.0.0. The objective of this
guide is therefore twofold. First, it helps users migrate scripts
written against earlier development releases. Second, it documents which
behaviors are expected to remain stable after 1.0.0 and which
backend-specific objects should never be treated as stable package
contracts.

``` r

library(sciModelFlowR)
smf_deprecation_policy()
head(smf_api_catalog())
```

# 2. Compatibility principles

Portable scientific specifications and package-native result semantics
are the compatibility target. Backend-native objects, optimizer
internals, GPU kernels, third-party serialization formats, and
incidental printed output are not. An old portable `ExperimentSpec` may
omit fields added later; deserialization supplies backward-compatible
defaults for those optional components. This differs from loading an
arbitrary historical R object with
[`readRDS()`](https://rdrr.io/r/base/readRDS.html), which is both less
portable and potentially unsafe when the source is not trusted.

When migrating, preserve the scientific question before preserving
syntax. If an older script accidentally fitted preprocessing on the full
dataset, reproducing that exact behavior is not desirable compatibility.
The correct migration is to the managed training-only pathway, with the
methodological change documented. Similarly, if an older analysis used
random row cross-validation despite grouped sampling, the package should
not reproduce the invalid geometry merely to match historical numbers.

# 3. Release-by-release migration

## 4. 0.1.0: Foundations, data, design, and contracts

The initial release established the S7 specification grammar, structured
conditions, capability registry, data auditing, design declarations,
training-only preprocessing, holdout manifests, package-native results,
reference lm/glm adapters, provenance, six initial Gold fixtures, and a
reproducibility manifest. Migration from ad hoc scripts means declaring
target, predictors, IDs, design, preprocessing, resampling, model,
metrics, and reproducibility explicitly. The most important behavioral
change is that preprocessing state is learned only on training
observations. Code that previously standardized a full data frame before
splitting should move scaling and imputation into `PreprocessSpec` and
managed experiment fitting. Stable IDs should be supplied whenever split
membership needs to be portable or compared across languages.
Backend-native objects remain accessible through an explicit escape
hatch, but ordinary downstream code should depend on package-native
results. This separation is essential because the package can evolve
backend adapters without changing the scientific meaning of a result.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

## 5. 0.2.0: Resampling, bootstrap, and feature learning

Version 0.2.0 expanded validation geometry and introduced design-aware
resampling, bootstrap schemes, supervised feature selection,
representation learning, and fold-safe execution. Migration requires
moving any feature selection, PCA, PLS, balancing, or learned
transformation inside the analysis fold. Grouped, temporal, spatial,
blocked, Monte Carlo, and nested structures should be chosen from the
scientific unit rather than as interchangeable cross-validation styles.
Bootstrap users must identify the sampling unit and dependence
structure; cluster or block bootstrap should replace case bootstrap when
independent rows are not the resampling unit. RFE and sequential
selection became package-native, but their use does not remove the need
for an outer assessment layer. The main compatibility rule is that older
`ExperimentSpec` objects remain readable; new feature components are
optional and default to no feature learning when absent.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

## 6. 0.3.0: Supervised ML, probability, calibration, and imbalance

Version 0.3.0 added supervised adapters, multiclass probability
contracts, proper probability scoring, calibration, imbalance handling,
and threshold-aware classification. Migration from hard-class workflows
should retain probabilities long enough to evaluate log loss, Brier
score, calibration, discrimination, and threshold consequences
separately. Sampling or SMOTE-like operations belong only in analysis
data. Assessment prevalence should be preserved unless the scientific
estimand explicitly specifies a different distribution. Probability
calibration requires a protected development source and must not use
final-test labels. Tidymodels, mlr3, and XGBoost remain optional engines
behind common package contracts. Scripts that directly inspect backend
prediction formats should migrate to `PredictionResult` or
`PredictionDistribution`, because column naming and backend-specific
return objects are not stable cross-backend interfaces.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

## 7. 0.4.0: Tuning and scientific benchmarking

Version 0.4.0 added conditional search spaces, random/grid search,
racing, Bayesian optimization, successive halving, Hyperband,
multiobjective Pareto analysis, nested tuning, and scientific
benchmarking. The migration principle is to distinguish inner selection
from outer generalization. A final test set or external domain is not a
hyperparameter resource. Existing code that chooses the best
configuration on the same folds used for reporting should move selection
into inner resampling and reserve outer folds for unbiased assessment.
Benchmarking also changed from a leaderboard mentality to evidence on
shared splits, dispersion, compute, stability, and explicit decision
rules. When objectives conflict, the package does not infer a universal
winner unless the analyst supplies a rule such as weighted or
lexicographic preference.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

## 8. 0.5.0: Explainability and explanation stability

Version 0.5.0 introduced package-native XAI contracts, permutation
importance, PDP, ICE, ALE, local perturbations, optional SHAP,
counterfactual candidates, source-feature tracing, extrapolation
diagnostics, and explanation stability. Migration requires removing
causal wording from ordinary model explanations unless an independent
causal identification strategy exists. Correlated predictors can
redistribute importance; transformed spectral or latent features need
source mapping before biological interpretation. Explanations should be
generated after diagnostics and evaluated across design-aware resamples
when they support substantive conclusions. Code that stores a single
SHAP table as definitive explanation evidence should migrate to an
`ExplainResult` plus, when relevant, `ExplanationStabilityResult`. Final
or external test data should not be repeatedly reused to stabilize
explanations because that converts protected assessment information into
a development resource.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

## 9. 0.6.0: Deep Learning and probabilistic Deep Learning

Version 0.6.0 added torch-centered architecture and trainer contracts
for tabular, convolutional, recurrent, TCN, Transformer, ViT,
autoencoder, VAE, transfer, multimodal, and multitask workflows, plus
probabilistic neural heads, ensembles, MC dropout, checkpoints, and
gradient explanations. Migration requires an explicit distinction
between training data, development validation used for early stopping,
and final or external assessment. Neural checkpoint loading is a trust
boundary. Tensor shapes are validated against architecture contracts
rather than silently reshaped. CUDA and mixed precision are optional
capabilities, not package requirements. Analysts moving from custom
torch loops should preserve the package manifest, partition roles,
seeds, checkpoint hashes, and uncertainty semantics. Integrated
Gradients, saliency, gradient-times-input, and Grad-CAM describe model
sensitivity and remain non-causal.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

## 10. 0.7.0: Bayesian modeling, conformal prediction, and typed uncertainty

Version 0.7.0 completed the Bayesian and conformal layers. Bayesian
workflows now record priors, posterior draws, diagnostics, posterior
predictive checks, PSIS-LOO where supported, model comparison, and
stacking. BART and Gaussian-process adapters remain optional. Conformal
workflows distinguish split, CV+, quantile, APS, calibration roles, and
exchangeability declarations. Migration requires naming interval
semantics explicitly: confidence, credible, posterior predictive,
bootstrap, model-prediction, and conformal intervals or sets are not
interchangeable. Code that labels every interval as a confidence
interval should be corrected. Conformal calibration and final test sets
must not overlap. Aleatoric and epistemic decomposition should be
reported only when identifiable from the method rather than inferred
from two arbitrary variance summaries.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

## 11. 0.8.0: Tracking, persistence, deployment, and scalable inference

Version 0.8.0 added dependency-light local tracking, optional MLflow,
secure bundles, portable state for supported stats workflows,
opaque-state trust gates, checksum validation, batch prediction, resume
checkpoints, iterators, hardware provenance, pins/vetiver/Plumber
adapters, and scalability utilities. Migration should separate
operational reproducibility from scientific validity. A bundle that
reloads successfully proves persistence, not external generalization.
Opaque RDS objects and neural checkpoints require `trusted = TRUE`.
Corrupted checksums or incompatible major schemas are blocking.
Calibration state must be replayed after reload. Batch resume uses data
identity and row-order checks so that a resumed job cannot silently
append predictions from a different input. Optional deployment services
remain outside core Imports.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

## 12. 0.9.0: Integrated scientific release candidate

Version 0.9.0 integrates the preceding layers, adds first-class external
validation, completes publication reporting, freezes the candidate API,
completes the formal Gold suite, expands neutral R/Python fixtures, adds
reference validation, backend quarantine metadata, domain curricula, and
migration/deprecation policy. The key migration rule is that internal
development evidence and protected external evidence remain separate.
[`smf_external_validate()`](https://wep69.github.io/sciModelFlowR/reference/external-validation-090.md)
replays a frozen workflow without refitting preprocessing, features,
model parameters, calibration, or thresholds.
[`smf_reporting_checklist()`](https://wep69.github.io/sciModelFlowR/reference/reporting-090.md)
and publication helpers make missing scientific reporting elements
visible. The API freeze means that changes between 0.9.0 and 1.0.0
should be limited to blockers discovered during local certification.
Optional backends are not considered release-certified merely because
their adapter code exists; pending engines remain quarantined until the
final validation campaign.

**Migration checkpoint.** Confirm that serialized specifications from
this stage still reconstruct, that newly optional components default
safely when absent, and that any change in numerical output can be
traced to a documented scientific correction, backend version, random
process, or validation geometry rather than an unexplained change in
semantics.

# 13. Stable contracts entering 1.0.0

The composition root remains `ExperimentSpec`. `TaskSpec` and
`DesignSpec` remain explicit rather than inferred entirely from column
classes. Preprocessing and supervised feature learning remain
training-only. Final test labels remain unavailable to tuning,
calibration, explanation stabilization, early stopping, and other
development decisions. Backend capabilities remain explicit. Ordinary
results remain package-native. `PredictionDistribution` and typed
uncertainty remain the common probabilistic language. Managed
experiments continue to emit manifests. Optional heavy dependencies
remain outside core Imports. Public outputs continue to carry warnings
and provenance.

These contracts are more important than exact argument ordering or
printed formatting. A future 1.x enhancement may add a new optional
field, new backend adapter, or new report renderer without changing the
meaning of a fitted result. Removing or redefining a scientific contract
requires a documented deprecation process rather than silent behavior
change.

# 14. Serialization migration

Portable JSON/YAML created through the package should be preferred for
specifications and metadata. Each serialized class includes a class
identifier that is reconstructed through the package class map. When
later releases added feature, calibration, tuning, explanation,
conformal, tracking, persistence, deployment, or scalability components,
older `ExperimentSpec` payloads were given explicit `NULL` defaults
during reconstruction. Run manifests similarly gained hardware
information with backward-compatible defaults.

Persistence bundles use a different contract because they may contain
executable or opaque backend state. Bundle schema compatibility is
checked before unsafe loading. A major incompatible bundle schema is
rejected with migration guidance. Checksums are validated before model
state is trusted. Portable safe-state paths are preferred where
supported. Opaque model state and checkpoints require an explicit
`trusted = TRUE` decision and should never be accepted from an
unverified source solely because they were produced by an older
sciModelFlowR version.

# 15. Randomness and reproducibility migration

R and Python are not required to generate identical pseudo-random
streams from the same integer seed. Cross-language parity is defined
through frozen data, stable IDs, neutral split manifests, expected
scientific quantities, tolerances, and algorithm-version metadata.
Within R, deterministic pathways should reproduce under their documented
seed and hardware assumptions. GPU or stochastic algorithms may be
classified as seed-stable within tolerance rather than bitwise
deterministic.

When an old analysis is migrated, preserve its seed as provenance but do
not assume that a newer backend version must produce the same stochastic
sample. Compare the scientific quantity and the declared tolerance. For
final validation, archive dependency versions, package version, hardware
metadata, split hashes, Gold hashes, and the complete manifest so that
differences can be investigated rather than hidden.

# 16. Metric and uncertainty migration

Do not migrate merely by renaming columns. Verify that the metric is
evaluated on the same scale, aggregation unit, and probability
representation. A hard-class accuracy result cannot be compared directly
with log loss. Macro and micro multiclass summaries answer different
questions. RMSE averaged across folds is not the same object as RMSE
computed after pooling all held-out predictions when fold sizes differ.

Uncertainty labels require even stricter migration. A bootstrap
percentile interval retains its resampling interpretation; a Bayesian
credible interval retains a posterior interpretation; a posterior
predictive interval includes outcome variability conditional on the
model; a conformal interval or prediction set has a coverage target
under its calibration assumptions. The 0.7.0 typed uncertainty layer
exists specifically to prevent historical reports from collapsing these
statements into one generic interval column.

# 17. Backend migration

Backend adapters are isolated from the core schema. An analysis should
therefore be reproducible at two levels: the package-native scientific
specification and the backend-specific computational environment. If a
third-party package changes parameter names or prediction formats, the
adapter can be updated while preserving the package result contract. If
the underlying algorithm changes materially, the backend version and,
where appropriate, an algorithm-version identifier should be recorded.

The 0.9.0 backend matrix deliberately quarantines optional engines
pending the final local validation campaign. Quarantine does not mean
the adapter is absent. It means the project does not yet make a 1.0.0
certification claim for that environment. Users who need an optional
backend before certification should record the exact package versions
and treat the result as an advanced or experimental pathway according to
the capability registry.

# 18. Reporting migration

Earlier versions returned a compact report structure. Version 0.9.0
completes the reporting layer with package-native publication tables,
figures, reporting checklists, external-validation evidence, and a
`ReportingResult`. Migration should preserve the underlying numeric data
as authoritative. Rendering to Markdown or another format must not
change estimates or uncertainty. Observed data should remain visible in
figures when scientifically appropriate. Reports should name validation
geometry, model/backend version, tuning protocol, metric definitions,
calibration and threshold rules, uncertainty type, explanation method,
external validity, and reproducibility identifiers.

A reporting artifact should not make a stronger claim than the result
supports. If external validation is absent, state that limitation. If a
backend remains quarantined, do not describe it as release-certified. If
a Bayesian or conformal workflow has not passed its required
diagnostics, do not hide that status in a polished table.

# 19. Deprecation policy for 1.x

The release-candidate policy returned by
[`smf_deprecation_policy()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md)
freezes the 0.9.0 public symbols for the 1.0.0 transition. Changes
before 1.0.0 are limited to blockers discovered during certification:
critical scientific errors, security defects, numerical failures,
installation blockers, API inconsistencies that prevent valid execution,
documentation that teaches a scientifically invalid workflow, or
metadata defects that invalidate the release. Cosmetic redesign and
convenience renaming should wait.

After 1.0.0, a public contract should normally enter a documented
deprecated state before removal. The deprecation notice should identify
the replacement, explain any semantic difference, and provide a
migration example. Serialized portable contracts need explicit migration
logic. Backend-native escape hatches remain exempt from stable
serialization guarantees because their structure belongs to the external
package.

# 20. Migration audit checklist

Before declaring an older analysis migrated, verify: target and unit of
analysis; groups, blocks, hierarchy, time, space, and external domains;
split geometry; training-only preprocessing; feature-selection location;
imbalance handling; calibration source; threshold source; model/backend
versions; tuning and outer assessment separation; metrics and
aggregation; uncertainty semantics; explanation stability; external
validation status; bundle trust and checksums; run manifest;
Gold/reference validation where relevant; and any numerical differences
from the historical result.

The migration is complete only when differences are explainable.
Matching an old number by reproducing leakage or an invalid design is
not successful migration. Conversely, a small numerical difference
caused by a backend update may be acceptable when reference tests, Gold
properties, diagnostics, and scientific conclusions remain within
declared tolerances.

# 21. From 0.9.0 to 1.0.0

The final validation campaign should install the package in clean
supported R environments, execute
unit/integration/numerical/Gold/reference/cross-language suites,
exercise core and optional backend matrices, render the Quarto/Jupyter
curriculum, verify bundle round-trips and security guards, build the
pkgdown site, and run `R CMD build` plus `R CMD check --as-cran`. Any
source change made after that campaign begins should be classified as a
blocker correction and should trigger the relevant validation subset
again.

The 1.0.0 source snapshot should therefore be understood as the
certified form of this 0.9.0 scientific grammar, not a new redesign.
That is why the API freeze occurs now.

# 22. Final perspective

The package evolved by adding capabilities around a stable scientific
sequence rather than by replacing one modeling fashion with another.
Migration succeeds when an older workflow can be expressed with clearer
design, stricter leakage boundaries, better uncertainty semantics, safer
persistence, and stronger external evidence while preserving the
original scientific objective. Version 0.9.0 is the point at which that
grammar is considered complete enough to certify rather than expand.

# 23. Detailed migration patterns

## 23.1 Full-data scaling to training-only preprocessing

A common historical script first called
[`scale()`](https://rdrr.io/r/base/scale.html) on every row and then
created train and test partitions. Migrating that script requires more
than changing syntax. Define predictors and target with
[`smf_data_spec()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md),
create `smf_preprocess_spec(center = TRUE, scale = TRUE)`, and let the
managed experiment fit centers and scales on the analysis partition. The
resulting coefficients may differ from the historical script because the
historical test values influenced the transformation. That difference is
expected and should be documented as a leakage correction. If feature
selection or imputation was also performed before the split, move those
operations into the same managed analysis boundary. Validation should
then compare the corrected workflow with an independent reference
implementation that uses the same training-only estimates. Do not tune
tolerances merely to recreate the leaked result.

## 23.2 Random folds to grouped folds

Suppose an earlier study measured several plants within the same plot or
several plots within the same field and used ordinary random k-fold
cross-validation. Migration begins by identifying the unit that can
recur and declaring it in `DesignSpec`. Group-aware resampling should
then keep that entity on one side of each split. Report both the
historical and corrected validation estimates only if the comparison is
scientifically useful; they estimate different generalization problems.
A rise in error after grouped validation is not a software regression.
It may be evidence that the random-fold estimate benefited from
dependence across folds. Preserve the grouped split manifest so that
model families can be compared on identical assessment units and so the
corresponding Python workflow can consume the same membership.

## 23.3 Random folds to temporal assessment

For time-indexed climate, sensor, growth, or pest series, random folds
may allow future values to inform earlier predictions indirectly through
preprocessing, feature selection, or correlated outcomes. Migration
requires an explicit time column and a forecasting or interpolation
statement. Use expanding, sliding, or blocked time resampling consistent
with that statement. Any lagged predictors must be constructed without
future information. Early stopping and model selection use development
windows, not the final future period. If the series is nonstationary,
add domain-shift diagnostics rather than averaging early and late
periods into a single performance estimate. Historical random-CV numbers
should not be treated as directly comparable to time-aware estimates.

## 23.4 Unprotected feature selection to nested feature learning

An older analysis may have screened variables once on the full dataset
and then cross-validated the selected model. This leaks assessment
outcomes into the predictor set whenever selection is supervised and can
also leak unsupervised distributional information. Migration places
feature screening, RFE, sequential selection, PLS, PCA state, or
stability selection inside each analysis fold. The selected variables
may change across folds; that variation is scientifically informative.
Use feature-stability summaries when the selected set supports
biological interpretation. If a final model is later refit on all
development data, record that refit separately from the out-of-fold
evidence used to estimate performance.

## 23.5 Oversampling before splitting to fold-safe imbalance handling

A historical classification pipeline may create synthetic minority
observations before cross-validation. This allows related synthetic
points to appear in both analysis and assessment and changes assessment
prevalence. Migration specifies the imbalance method in `ImbalanceSpec`
and applies it only to analysis data. The assessment fold remains
untouched. If class weights are used, weights belong to model fitting
rather than to outcome relabeling. Compare balanced accuracy or
class-specific metrics when they answer the scientific decision problem,
but keep proper probability scores if probabilities are used downstream.
Calibration should be estimated after the imbalance-adjusted model is
fitted, using a protected development calibration source.

## 23.6 Final-test threshold optimization to protected threshold selection

Thresholds are parameters of a decision procedure even when the
underlying probabilistic model is fixed. If an older script chose the
threshold that maximized F1 or sensitivity on the final test set, the
final set became development data. Migration should reserve a
calibration or validation partition inside development for threshold
choice and leave the final labels inaccessible until the procedure is
frozen. Report the selected threshold, selection criterion, prevalence
of the selection source, and the final metric separately. If the
deployment prevalence differs, a fixed threshold may need a
decision-theoretic justification rather than repeated empirical
retuning.

## 23.7 Single tuning loop to nested model selection

When hyperparameters are selected and reported on the same resamples,
performance is optimistically coupled to selection. Migration uses an
inner resampling layer to rank configurations and an outer layer to
estimate the performance of the complete selection procedure. The result
should retain both inner search evidence and outer generalization
evidence. Search algorithms such as racing, Bayesian optimization, or
Hyperband can reduce computation, but none changes the need for an outer
assessment when a less biased estimate of model-selection performance is
required. Final external validation, if available, remains downstream of
nested development and should not become an additional optimization
loop.

## 23.8 Leaderboard selection to scientific benchmarking

A table sorted by mean RMSE or AUC often hides dispersion, calibration,
uncertainty, compute cost, and instability. Migration to
[`smf_benchmark()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md)
should place candidates on identical split manifests and retain
fold-level evidence. If objectives conflict, use a declared Pareto or
decision rule rather than allowing table order to imply a universal
winner. Keep a baseline candidate. A more complex learner should earn
its complexity through a scientifically relevant gain, not merely a
small average improvement within sampling noise. If two models are
effectively indistinguishable for the intended decision, the reporting
layer should make that ambiguity visible.

## 23.9 One-off explanations to stable explanation evidence

If an older manuscript reports one permutation-importance ranking or one
SHAP plot from the final fitted model, migration should separate
prediction validation from explanation stability. Generate explanations
on appropriate development or assessment predictions according to the
intended question and evaluate whether the ranking or shape persists
across design-aware resamples. Correlated predictors may exchange rank
while representing the same underlying signal. Trace transformed
features to source variables before biological interpretation. Preserve
the package non-causal flag. Explanations can support understanding of
model behavior but cannot convert a predictive association into a
treatment effect.

## 23.10 Generic intervals to typed uncertainty

Historical code frequently labels every lower/upper pair as a confidence
interval. Migration requires identifying the generating method and
target. A bootstrap interval may quantify resampling variation in an
estimator. A Bayesian credible interval describes posterior parameter
uncertainty. A posterior predictive interval concerns future outcomes. A
model-based prediction interval follows its parametric assumptions. A
conformal interval targets predictive coverage under calibration
assumptions. Store the corresponding `UncertaintyDescriptor` and use
accurate terminology in tables and captions. If the historical method
cannot be reconstructed, report the interval type as unresolved rather
than assigning a convenient label.

## 23.11 Ad hoc Bayesian summaries to a complete Bayesian workflow

An older Bayesian script may report posterior means and 95% intervals
without prior predictive checks, convergence diagnostics, or predictive
assessment. Migration should reconstruct the prior rationale, inspect
whether priors generate plausible outcomes, fit with a supported
backend, evaluate chain diagnostics and effective sample behavior,
inspect posterior predictive fit, and use PSIS-LOO or another justified
method for predictive comparison when appropriate. Store posterior draws
through package contracts rather than assuming a backend-specific draw
class is permanent. If diagnostics are unacceptable, the result should
remain flagged; reporting functions should not convert an unresolved
sampler problem into a polished final table.

## 23.12 Model persistence to secure bundles

A historical analysis may save a fitted object with
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) and later load it
directly for deployment. Migration distinguishes trusted internal state
from portable verified state. Where supported, use a safe bundle with
schema, preprocessing, feature state, model state, calibration, labels,
manifest, and checksums. Validate checksums before prediction. Opaque
backend objects require explicit trust and compatible package versions.
After reload, compare predictions with the live workflow on a frozen
input fixture. A successful round trip verifies persistence semantics;
it does not validate future deployment populations. Track those as
separate operational and scientific checks.

## 23.13 Internal cross-validation to protected external validation

If a manuscript calls one cross-validation fold “external,” migration
should correct the terminology. External validation requires a domain
protected from model-development decisions, such as a new site, season,
instrument, region, or population. Version 0.9.0 provides
[`smf_external_validate()`](https://wep69.github.io/sciModelFlowR/reference/external-validation-090.md)
to replay a frozen fitted pipeline on that domain without refitting
preprocessing, feature state, model parameters, calibration, or
thresholds. Internal and external metrics remain separate, and
predictor-shift diagnostics are attached. If no protected domain exists,
report strong internal validation plus a limitation. Do not manufacture
externality through renaming.

## 23.14 Manual result copying to publication reporting

Older workflows often copy model summaries into spreadsheets and
manually assemble figures, which can separate numbers from their
provenance. Migration uses
[`smf_publication_table()`](https://wep69.github.io/sciModelFlowR/reference/reporting-090.md),
[`smf_publication_plot()`](https://wep69.github.io/sciModelFlowR/reference/reporting-090.md),
[`smf_reporting_checklist()`](https://wep69.github.io/sciModelFlowR/reference/reporting-090.md),
and
[`smf_report()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md)
so that tables and figures are derived from package-native results. The
numeric result remains authoritative, while rendering is presentation.
Include run ID, backend version, split or external domain, uncertainty
type, calibration method, and relevant warnings. A report should make
missing evidence visible rather than hiding it. This is especially
important in the release candidate because the package itself
distinguishes implementation completeness from deferred runtime
certification.

# 24. Compatibility questions to ask during local validation

For every migrated workflow, ask whether the target variable has the
same definition and units, whether factor levels and positive labels are
unchanged, whether preprocessing parameters are estimated from the same
analysis observations, whether split membership is the same or
intentionally corrected, whether the backend algorithm and version
match, whether seeds govern the same stochastic operation, whether
metrics aggregate over the same units, whether uncertainty targets are
semantically identical, and whether any external domain was touched
during development. A numerical discrepancy that can be traced to one of
these causes should be documented with the relevant hash, version, or
scientific correction. An unexplained discrepancy is a validation
failure until investigated.

The local campaign should therefore preserve both machine-readable and
narrative evidence. Machine-readable evidence includes manifests, Gold
hashes, API hashes, backend versions, split manifests, reference
tolerances, and test outputs. Narrative evidence explains why a change
was intentional and whether it alters the scientific conclusion.
Together these forms of evidence make migration auditable instead of
merely reproducible on one computer.

# 25. Practical migration sequence for an existing project

Start by freezing the historical project before editing it. Save the
original data hashes, package versions, scripts, model outputs, seeds,
and any split identifiers that still exist. The purpose is not to
preserve an invalid workflow forever; it is to create evidence that
allows every change to be explained. Next, rewrite the scientific target
in plain language and identify the future unit to which the model is
meant to generalize. That statement determines which historical choices
can be retained and which need methodological correction.

Create `DataSpec`, `TaskSpec`, and `DesignSpec` before translating model
code. Confirm IDs, response units, group variables, time, coordinates,
external domains, and hierarchy against the original study design. Run
the data audit and resolve blocking leakage defects. Reconstruct a
validation geometry consistent with the claim, ideally through stable
ID-based manifests. If the historical split is scientifically
defensible, preserve it as a fixture. If it is not, keep the old result
only as a comparison and create a corrected split with a documented
reason.

Then migrate preprocessing and feature learning. List every quantity
historically estimated from data: means, scales, imputation values,
encodings, variable screens, PLS/PCA components, oversampling, learned
embeddings, and augmentation rules. Place each operation inside the
appropriate analysis boundary. Validate the transformed dimensions and,
when feasible, compare one fold against an independent implementation.
Only after this layer is stable should the model backend be translated.
Start with the simplest reference model that expresses the same task,
then add the historical engine and compare predictions on a frozen
input.

Migrate evaluation next. Recalculate metrics from frozen predictions
rather than copying historical summaries. Check positive-class
definitions, multiclass averaging, weights, missing-value handling, and
aggregation across folds. If the analysis is probabilistic, evaluate
probabilities before thresholds. Reconstruct calibration and threshold
sources and verify that final assessment labels were not used. For
uncertainty, identify the original method and replace generic labels
with typed semantics. If the historical interval method is unclear,
record that uncertainty as unresolved instead of guessing.

If the project includes tuning, explanations, Bayesian inference, neural
networks, or deployment, migrate these after the deterministic core is
verified. Tuning must preserve inner/outer boundaries. Explanations must
retain non-causal semantics and should be checked for stability.
Bayesian models require prior and posterior diagnostics. Neural models
require partition roles, tensor-shape checks, checkpoint trust, and
deterministic-policy documentation. Deployment requires bundle checksums
and prediction-equivalence tests after reload.

Finally, generate the package reporting checklist and compare it with
the historical manuscript, thesis, or report. Missing design
information, external-validation status, uncertainty definitions,
backend versions, or explanation limitations should be repaired in the
scientific narrative, not only in code. Run Gold, reference, and
cross-language validation. Archive the new run manifest, API-freeze
hash, backend matrix, and all validation outputs. At this stage, the
migrated project should be understandable without the historical
analyst’s memory.

# 26. Changes that should wait until after 1.0.0

The period between 0.9.0 and 1.0.0 is for certification and blocker
correction, not another architecture cycle. New convenience aliases,
speculative backend integrations, alternative class hierarchies,
cosmetic renaming, and broad new modeling families should normally wait.
Introducing them now would expand the validation surface precisely when
the project needs to reduce uncertainty about existing contracts. If
local testing identifies a critical scientific defect, security
vulnerability, broken installation pathway, serialization
incompatibility, or documentation example that violates safeguards, fix
it and rerun the affected validation layers. Otherwise preserve the API
freeze.

After 1.0.0, enhancements can resume under semantic versioning and a
documented lifecycle. New capabilities may be added in minor releases
when they preserve stable contracts. Breaking changes require stronger
justification and an explicit migration path. This discipline allows the
package to keep evolving scientifically without forcing every research
project to rewrite its analysis whenever a backend or modeling fashion
changes.

# 27. Final migration record

A completed migration should leave a short record that another analyst
can audit. Record the historical package or script version, the new
sciModelFlowR version, old and new data hashes, old and new split
definitions, backend versions, seed policy, scientific corrections,
numerical differences outside tolerance, and the validation commands
executed. Separate changes that alter only presentation from changes
that alter the estimand, assessment domain, preprocessing state,
algorithm, or uncertainty statement. The latter require scientific
review even when software tests pass.

For a manuscript already under review, do not silently replace
previously reported numbers. Maintain a reconciliation table that
identifies the original value, migrated value, cause of change, and
whether the interpretation changes. Leakage corrections or stronger
external validation can legitimately worsen headline performance while
increasing credibility. The correct objective is not numerical
continuity at any cost; it is a scientifically defensible analysis whose
differences are traceable.

The final local validation campaign will create the certification
evidence needed to convert this release candidate into 1.0.0. Until that
evidence exists, the source tree is implementation-complete but
validation-deferred. That distinction should remain visible in
software-paper text, release notes, and teaching material.

A useful final rule is to preserve evidence before preserving
convenience. If a migration choice cannot be justified from the
scientific design, validation target, or reproducibility record, it
should not be hidden behind backward-compatibility language.
Compatibility is valuable when it preserves meaning; it is harmful when
it preserves a known defect. Version 0.9.0 treats that distinction as
part of the release contract.
