# sciModelFlowR 0.3.0: Supervised Machine Learning

## Supervised machine learning without losing the scientific design

This vignette is the focused supervised-learning tutorial for
`sciModelFlowR` 0.3.0. The package does not define supervised learning
as a contest among algorithms. It defines it as a sequence in which the
task, observational unit, design, preprocessing boundary, resampling
geometry, feature-learning boundary, estimator, prediction scale, and
evaluation metric are declared and preserved. Version 0.3.0 adds
optional adapters for `tidymodels`/`parsnip`, `mlr3`, and XGBoost while
retaining transparent `stats` reference models.

The scientific rule is:

**Choose the prediction target and validation unit first. Fit every
learned operation on analysis data only. Compare backends on the same
scientific splits.**

The Gold datasets are synthetic teaching and validation fixtures, not
empirical agronomic evidence.

### 1. Learning objectives

After completing this vignette, the reader should be able to:

1.  distinguish task specification from model specification;
2.  select a supervised backend without changing the validation
    question;
3.  use `stats` as a numerical reference adapter;
4.  understand the standardized adapter interface for `tidymodels`,
    `mlr3`, and XGBoost;
5.  obtain regression predictions, binary probabilities, and multiclass
    probabilities through one package contract;
6.  recognize when multi-output regression is supported and when a
    backend must be rejected;
7.  keep preprocessing and feature learning inside each resample;
8.  use probability-aware metrics for classification rather than relying
    only on accuracy;
9.  verify backend equivalence against direct predictions within
    tolerance;
10. report backend identity, engine version, split identity, metrics,
    warnings, and limitations.

### 2. The adapter contract

The core supervised functions are:

``` r

smf_model_spec()
smf_available_model_adapters()
smf_fit_model()
smf_predict_model()
smf_fit_experiment()
smf_resample_experiment()
```

[`smf_fit_model()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md)
accepts a package `TaskSpec`, a `ModelSpec`, predictors, outcomes, and
optional analysis weights. It returns an internal standardized adapter
record. The native model remains available only as an escape hatch.
[`smf_predict_model()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md)
converts backend-specific outputs to a common response or probability
representation.

This distinction is important. A parsnip `model_fit`, an mlr3 `Learner`,
an XGBoost booster, and an `lm` object have different internal
structures. Scientific reporting should not depend on those structures.
The package result stores the backend identity while presenting
predictions and metrics in stable package-native objects.

### 3. Start with a transparent regression baseline

``` r

library(sciModelFlowR)

d <- smf_load_dataset("gold_linear_regression")

spec <- smf_experiment_spec(
  task = smf_task_spec("regression", "yield"),
  data = smf_data_spec(
    target = "yield",
    predictors = c("nitrogen", "rainfall", "soil_n"),
    id_column = "obs_id"
  ),
  design = smf_design_spec(id_column = "obs_id"),
  preprocessing = smf_preprocess_spec("median", center = TRUE, scale = TRUE),
  resampling = smf_resampling_spec("holdout", train_prop = 0.80, seed = 260915L),
  model = smf_model_spec("linear_regression", "stats"),
  metrics = list(smf_metric_spec("rmse"), smf_metric_spec("mae"))
)

fit <- smf_fit_experiment(spec, d)
fit
```

The purpose of the baseline is not to declare linear regression
universally preferable. It gives a transparent numerical reference and a
simple test of the full workflow. If a later random forest or boosted
tree appears substantially better, the analyst can ask whether the
improvement reflects legitimate nonlinear structure or a change in
preprocessing, resampling, target definition, or leakage.

### 4. Direct backend equivalence

The 0.3.0 tests compare adapter predictions with direct backend
predictions. For the `stats` linear adapter, the expected relationship
is conceptually:

``` r

native <- smf_backend_object(fit)
held_out <- d[fit@split@test_index, ]
x_test <- smf_apply_preprocessor(fit@fit@preprocessing, held_out)

p_native <- predict(native, newdata = x_test)
p_smf <- fit@prediction@estimate

max(abs(p_native - p_smf))
```

The tolerance should be numerical, not rhetorical. A wrapper is only
trustworthy if it can be shown to preserve the backend computation for a
frozen fixture.

### 5. `tidymodels` through a package-native contract

The adapter maps scientific model families to parsnip specifications. A
user can request a random forest without exposing the fitted `ranger`
object as the public result contract.

``` r

rf_spec <- smf_model_spec(
  family = "random_forest",
  engine = "tidymodels",
  parameters = list(
    model_engine = "ranger",
    model_args = list(trees = 500L, min_n = 5L)
  )
)
```

The preprocessing already fitted by `sciModelFlowR` is passed to the
adapter as a predictor table. This avoids fitting a second hidden recipe
outside the package’s provenance record. Case weights, when requested by
an imbalance specification and supported by the selected engine, are
converted to tidymodels importance weights.

The adapter is optional. If `parsnip`, the selected engine package, or
another required dependency is missing, the workflow should fail
clearly. It must not silently replace the requested model with `lm` or
another available estimator.

### 6. `mlr3` as an advanced supervised adapter

`mlr3` organizes modeling around tasks, learners, predictions, and
measures. In `sciModelFlowR`, those objects are internal implementation
details of the adapter. A learner ID can be supplied through
`ModelSpec`:

``` r

mlr_spec <- smf_model_spec(
  "random_forest",
  engine = "mlr3",
  parameters = list(
    learner_id = "regr.ranger",
    learner_params = list(num.trees = 500L)
  )
)
```

For classification, the adapter requests probability prediction when the
learner advertises that capability. The probability matrix is then
validated by the package. Rows must sum to one within tolerance, column
names must identify the classes, and unsupported probability operations
remain unavailable.

### 7. XGBoost

The XGBoost adapter uses the lower-level training interface intended for
package integration. The model family remains a `ModelSpec`, while
XGBoost-specific training parameters stay namespaced in
`parameters$params`.

``` r

xgb_spec <- smf_model_spec(
  "boosted_tree",
  engine = "xgboost",
  parameters = list(
    nrounds = 250L,
    params = list(
      max_depth = 4L,
      eta = 0.05,
      subsample = 0.8,
      colsample_bytree = 0.8
    )
  )
)
```

Version 0.3.0 does not tune these values automatically. Hyperparameter
optimization belongs to 0.4.0. A fixed XGBoost configuration can
therefore be compared on design-aware resamples, but the user should not
interpret the result as an optimized benchmark.

### 8. Binary classification is a probability problem

Use the frozen calibration fixture:

``` r

b <- smf_load_dataset("gold_binary_calibration")
b$event <- factor(ifelse(b$event == 1, "yes", "no"), levels = c("no", "yes"))

b_spec <- smf_experiment_spec(
  task = smf_task_spec("binary", "event", positive_label = "yes"),
  data = smf_data_spec("event", c("x1", "x2"), id_column = "obs_id"),
  design = smf_design_spec(id_column = "obs_id"),
  preprocessing = smf_preprocess_spec(center = TRUE, scale = TRUE),
  resampling = smf_resampling_spec(
    "stratified_holdout",
    train_prop = 0.75,
    strata = "event",
    seed = 260915L
  ),
  model = smf_model_spec("logistic_regression", "stats"),
  metrics = list(
    smf_metric_spec("log_loss"),
    smf_metric_spec("brier"),
    smf_metric_spec("roc_auc"),
    smf_metric_spec("pr_auc")
  )
)

b_fit <- smf_fit_experiment(b_spec, b)
```

The primary output for a probabilistic classifier is a probability
matrix, not only a hard class label. Accuracy discards the difference
between a prediction of 0.51 and 0.99 even though the two forecasts
carry very different confidence. Log loss and Brier score retain that
information.

### 9. Multiclass classification

`gold_multiclass_imbalanced` contains three overlapping classes, with
class `C` intentionally uncommon.

``` r

m <- smf_load_dataset("gold_multiclass_imbalanced")
m$class <- factor(m$class)

table(m$class)
```

The `true_p_*` columns are generator metadata and must not be used as
predictors. A valid multiclass model returns one probability column per
class. `sciModelFlowR` checks that each row sums to one and that
observed labels are represented by the probability columns.

A raw accuracy value is not an adequate summary when one class is rare.
At minimum, examine balanced accuracy, class-specific recall, log loss,
Brier score, and a PR-oriented measure when the scientific target
emphasizes rare-event detection.

### 10. Multi-output regression

The `TaskSpec` can declare multiple numeric targets. The 0.3.0 `stats`
adapter supports a transparent baseline by fitting one linear model per
target. This is intentionally conservative. A backend should not be
marked multi-output merely because it can accept a matrix; the package
must know the semantics of its fitting and prediction API.

Multi-output feature selection remains gated unless a method has an
explicit multivariate target contract. Reusing a univariate selection
score across multiple responses without declaring the reduction rule
would make the estimand ambiguous.

### 11. Fold-safe feature learning remains mandatory

A powerful learner does not relax the 0.2.0 safeguards. If PCA, PLS,
mutual-information selection, RFE, or another supervised feature
procedure is requested, it is learned independently inside each analysis
fold. The assessment fold is transformed using the learned state only.

This distinction becomes more important as algorithm flexibility
increases. Leakage can make a complex learner appear spectacular even
though the apparent advantage disappears under a correct fold boundary.

### 12. Design-aware resampling is shared across backends

The scientific comparison should hold split geometry constant while
changing the estimator.

``` r

r <- smf_make_resampler(d, spec@resampling, spec@design, spec@task)

lm_result <- smf_resample_experiment(spec, d, resamples = r)
# Replace only spec@model with another fixed backend configuration,
# then reuse the same ResampleCollection.
```

This makes the comparison conditional on the same held-out observations.
In grouped, temporal, spatial, or external validation, the same
principle is even more important because different split geometry can
change difficulty far more than the choice between two reasonable
algorithms.

### 13. Metrics are estimands too

RMSE emphasizes larger regression errors. MAE is easier to interpret as
a typical absolute deviation. R-squared describes variance relative to a
mean baseline and can behave differently under distribution shift. In
classification, accuracy, balanced accuracy, recall, specificity, MCC,
ROC-AUC, PR-AUC, log loss, and Brier score answer different questions.

No single metric should be called universally best. The package records
metric direction and decision role so that later benchmarking can
distinguish primary performance, calibration, safety, and descriptive
diagnostics.

### 14. Scientifically inappropriate workflow

The following idea is wrong:

> Generate a random row-wise split, run SMOTE on the full dataset,
> select variables using all rows, try many algorithms, and report the
> test performance of whichever model performs best.

It combines several sources of optimism. Synthetic examples can reflect
assessment labels, feature selection uses the test outcome, the test set
participates in algorithm selection, and the row-wise split may violate
the scientific unit. More compute does not repair those violations.

A defensible workflow declares the design, creates protected assessment
data, performs all learned operations only on analysis rows, and delays
model selection to a nested or otherwise independent tuning design when
required.

### 15. Reporting a supervised model

A useful methods section should report the target, prediction unit,
predictor availability time, resampling geometry, preprocessing steps,
feature-learning procedure, estimator family, computational engine,
fixed hyperparameters, probability threshold if relevant, metrics,
calibration status, random seeds, backend versions, and major scientific
warnings.

The model name alone is not a reproducible method. “XGBoost was used”
omits the data boundary, the objective, the feature representation, the
number of boosting rounds, the resampling scheme, and the decision rule.

### 16. Function-selection guide

| Question | Function |
|----|----|
| Which adapters are available? | [`smf_available_model_adapters()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md) |
| How do I declare a learner? | [`smf_model_spec()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md) |
| How do I fit one standardized adapter? | [`smf_fit_model()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md) |
| How do I predict from it? | [`smf_predict_model()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md) |
| How do I run a protected experiment? | [`smf_fit_experiment()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md) |
| How do I run design-aware folds? | [`smf_resample_experiment()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md) |
| How do I inspect the native object? | [`smf_backend_object()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md) |
| How do I score probabilities? | [`smf_evaluate()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md) and [`smf_evaluate_probabilistic()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md) |

### 17. Minimum supervised-learning checklist

target and prediction unit declared;

predictors available at intended prediction time;

groups, blocks, repeated units, time, space, and domains declared when
relevant;

preprocessing fitted only on analysis data;

feature learning fitted only on analysis data;

imbalance operations restricted to analysis data;

adapter capability checked before fitting;

class probabilities normalized and class names preserved;

calibration and test evidence separated;

multiple metrics chosen for scientific reasons;

backend equivalence test available for certified adapters;

manifest records backend, split, hashes, seed, and warnings.

#### Extended scenario 1: Genotype prediction across environments

A breeding study uses genotype and environment descriptors to predict
yield in environments not used for model fitting. In a `sciModelFlowR`
analysis, the first step is to translate this situation into an explicit
prediction target and a validation unit. Environment must define an
external or grouped validation domain before algorithm comparison. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is randomly mixing records from the same
environment across folds. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report environment-wise errors and compare them with the pooled metric.
The evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 2: Soil property mapping

A soil model predicts organic carbon from terrain and remote-sensing
covariates at sampled coordinates. In a `sciModelFlowR` analysis, the
first step is to translate this situation into an explicit prediction
target and a validation unit. Spatial blocks or location-aware folds
should represent geographic transfer. The important point is that the
estimator is not allowed to redefine the scientific question after
performance results are visible.

The main failure mode is neighbor leakage caused by random row-wise
cross-validation. A defensible workflow stores the split or resampling
geometry, fits all learned transformations only on analysis rows, and
evaluates the relevant quantities on held-out observations. Map held-out
residuals and summarize spatial separation of training and assessment
points. The evidence should be reported together with the model family,
backend, probability or response scale, warnings, seed, and manifest
hash. This keeps the result interpretable even if a different backend is
evaluated later.

#### Extended scenario 3: Hyperspectral disease classification

Multiple spectra are acquired from the same plant while disease status
is the target. In a `sciModelFlowR` analysis, the first step is to
translate this situation into an explicit prediction target and a
validation unit. Plant identity should remain intact across folds when
prediction concerns unseen plants. The important point is that the
estimator is not allowed to redefine the scientific question after
performance results are visible.

The main failure mode is splitting spectra from one plant between
training and assessment. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report plant-level grouping and class-wise probability metrics. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 4: Weather-driven yield prediction

Daily or seasonal predictors are used to predict future yield. In a
`sciModelFlowR` analysis, the first step is to translate this situation
into an explicit prediction target and a validation unit. Temporal
ordering must prevent future periods from informing past training
states. The important point is that the estimator is not allowed to
redefine the scientific question after performance results are visible.

The main failure mode is random cross-validation that trains on future
seasons. A defensible workflow stores the split or resampling geometry,
fits all learned transformations only on analysis rows, and evaluates
the relevant quantities on held-out observations. Show fold date ranges
and performance degradation under forward validation. The evidence
should be reported together with the model family, backend, probability
or response scale, warnings, seed, and manifest hash. This keeps the
result interpretable even if a different backend is evaluated later.

#### Extended scenario 5: Rare pest detection

A classifier identifies a low-prevalence pest event from sensor
features. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Use probability metrics and fold-safe imbalance handling, not accuracy
alone. The important point is that the estimator is not allowed to
redefine the scientific question after performance results are visible.

The main failure mode is a majority-class model appearing excellent
because prevalence is low. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report PR-AUC, recall, specificity, calibration, and threshold rule. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 6: Instrument transfer

A spectroscopy model is trained on one instrument and deployed on
another. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Instrument identity should define an external validation domain. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is pooling both instruments before random
splitting. A defensible workflow stores the split or resampling
geometry, fits all learned transformations only on analysis rows, and
evaluates the relevant quantities on held-out observations. Report
calibration transfer separately from within-instrument accuracy. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 7: Repeated greenhouse measurements

The same pot is measured repeatedly during growth. In a `sciModelFlowR`
analysis, the first step is to translate this situation into an explicit
prediction target and a validation unit. Pot or plant identity must stay
within one fold when the target is a new experimental unit. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is repeated rows making assessment observations
near-duplicates of training observations. A defensible workflow stores
the split or resampling geometry, fits all learned transformations only
on analysis rows, and evaluates the relevant quantities on held-out
observations. Report unit-level grouping and the number of independent
units per fold. The evidence should be reported together with the model
family, backend, probability or response scale, warnings, seed, and
manifest hash. This keeps the result interpretable even if a different
backend is evaluated later.

#### Extended scenario 8: Multi-output quality prediction

A model predicts several correlated laboratory traits from the same
spectra. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Each response and the multivariate evaluation rule must be declared. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is averaging target-specific errors without
documenting the scale or weighting. A defensible workflow stores the
split or resampling geometry, fits all learned transformations only on
analysis rows, and evaluates the relevant quantities on held-out
observations. Report metrics by target before any aggregate summary. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 9: Genotype prediction across environments

A breeding study uses genotype and environment descriptors to predict
yield in environments not used for model fitting. In a `sciModelFlowR`
analysis, the first step is to translate this situation into an explicit
prediction target and a validation unit. Environment must define an
external or grouped validation domain before algorithm comparison. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is randomly mixing records from the same
environment across folds. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report environment-wise errors and compare them with the pooled metric.
The evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 10: Soil property mapping

A soil model predicts organic carbon from terrain and remote-sensing
covariates at sampled coordinates. In a `sciModelFlowR` analysis, the
first step is to translate this situation into an explicit prediction
target and a validation unit. Spatial blocks or location-aware folds
should represent geographic transfer. The important point is that the
estimator is not allowed to redefine the scientific question after
performance results are visible.

The main failure mode is neighbor leakage caused by random row-wise
cross-validation. A defensible workflow stores the split or resampling
geometry, fits all learned transformations only on analysis rows, and
evaluates the relevant quantities on held-out observations. Map held-out
residuals and summarize spatial separation of training and assessment
points. The evidence should be reported together with the model family,
backend, probability or response scale, warnings, seed, and manifest
hash. This keeps the result interpretable even if a different backend is
evaluated later.

#### Extended scenario 11: Hyperspectral disease classification

Multiple spectra are acquired from the same plant while disease status
is the target. In a `sciModelFlowR` analysis, the first step is to
translate this situation into an explicit prediction target and a
validation unit. Plant identity should remain intact across folds when
prediction concerns unseen plants. The important point is that the
estimator is not allowed to redefine the scientific question after
performance results are visible.

The main failure mode is splitting spectra from one plant between
training and assessment. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report plant-level grouping and class-wise probability metrics. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 12: Weather-driven yield prediction

Daily or seasonal predictors are used to predict future yield. In a
`sciModelFlowR` analysis, the first step is to translate this situation
into an explicit prediction target and a validation unit. Temporal
ordering must prevent future periods from informing past training
states. The important point is that the estimator is not allowed to
redefine the scientific question after performance results are visible.

The main failure mode is random cross-validation that trains on future
seasons. A defensible workflow stores the split or resampling geometry,
fits all learned transformations only on analysis rows, and evaluates
the relevant quantities on held-out observations. Show fold date ranges
and performance degradation under forward validation. The evidence
should be reported together with the model family, backend, probability
or response scale, warnings, seed, and manifest hash. This keeps the
result interpretable even if a different backend is evaluated later.

#### Extended scenario 13: Rare pest detection

A classifier identifies a low-prevalence pest event from sensor
features. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Use probability metrics and fold-safe imbalance handling, not accuracy
alone. The important point is that the estimator is not allowed to
redefine the scientific question after performance results are visible.

The main failure mode is a majority-class model appearing excellent
because prevalence is low. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report PR-AUC, recall, specificity, calibration, and threshold rule. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 14: Instrument transfer

A spectroscopy model is trained on one instrument and deployed on
another. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Instrument identity should define an external validation domain. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is pooling both instruments before random
splitting. A defensible workflow stores the split or resampling
geometry, fits all learned transformations only on analysis rows, and
evaluates the relevant quantities on held-out observations. Report
calibration transfer separately from within-instrument accuracy. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 15: Repeated greenhouse measurements

The same pot is measured repeatedly during growth. In a `sciModelFlowR`
analysis, the first step is to translate this situation into an explicit
prediction target and a validation unit. Pot or plant identity must stay
within one fold when the target is a new experimental unit. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is repeated rows making assessment observations
near-duplicates of training observations. A defensible workflow stores
the split or resampling geometry, fits all learned transformations only
on analysis rows, and evaluates the relevant quantities on held-out
observations. Report unit-level grouping and the number of independent
units per fold. The evidence should be reported together with the model
family, backend, probability or response scale, warnings, seed, and
manifest hash. This keeps the result interpretable even if a different
backend is evaluated later.

#### Extended scenario 16: Multi-output quality prediction

A model predicts several correlated laboratory traits from the same
spectra. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Each response and the multivariate evaluation rule must be declared. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is averaging target-specific errors without
documenting the scale or weighting. A defensible workflow stores the
split or resampling geometry, fits all learned transformations only on
analysis rows, and evaluates the relevant quantities on held-out
observations. Report metrics by target before any aggregate summary. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 17: Genotype prediction across environments

A breeding study uses genotype and environment descriptors to predict
yield in environments not used for model fitting. In a `sciModelFlowR`
analysis, the first step is to translate this situation into an explicit
prediction target and a validation unit. Environment must define an
external or grouped validation domain before algorithm comparison. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is randomly mixing records from the same
environment across folds. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report environment-wise errors and compare them with the pooled metric.
The evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 18: Soil property mapping

A soil model predicts organic carbon from terrain and remote-sensing
covariates at sampled coordinates. In a `sciModelFlowR` analysis, the
first step is to translate this situation into an explicit prediction
target and a validation unit. Spatial blocks or location-aware folds
should represent geographic transfer. The important point is that the
estimator is not allowed to redefine the scientific question after
performance results are visible.

The main failure mode is neighbor leakage caused by random row-wise
cross-validation. A defensible workflow stores the split or resampling
geometry, fits all learned transformations only on analysis rows, and
evaluates the relevant quantities on held-out observations. Map held-out
residuals and summarize spatial separation of training and assessment
points. The evidence should be reported together with the model family,
backend, probability or response scale, warnings, seed, and manifest
hash. This keeps the result interpretable even if a different backend is
evaluated later.

#### Extended scenario 19: Hyperspectral disease classification

Multiple spectra are acquired from the same plant while disease status
is the target. In a `sciModelFlowR` analysis, the first step is to
translate this situation into an explicit prediction target and a
validation unit. Plant identity should remain intact across folds when
prediction concerns unseen plants. The important point is that the
estimator is not allowed to redefine the scientific question after
performance results are visible.

The main failure mode is splitting spectra from one plant between
training and assessment. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report plant-level grouping and class-wise probability metrics. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 20: Weather-driven yield prediction

Daily or seasonal predictors are used to predict future yield. In a
`sciModelFlowR` analysis, the first step is to translate this situation
into an explicit prediction target and a validation unit. Temporal
ordering must prevent future periods from informing past training
states. The important point is that the estimator is not allowed to
redefine the scientific question after performance results are visible.

The main failure mode is random cross-validation that trains on future
seasons. A defensible workflow stores the split or resampling geometry,
fits all learned transformations only on analysis rows, and evaluates
the relevant quantities on held-out observations. Show fold date ranges
and performance degradation under forward validation. The evidence
should be reported together with the model family, backend, probability
or response scale, warnings, seed, and manifest hash. This keeps the
result interpretable even if a different backend is evaluated later.

#### Extended scenario 21: Rare pest detection

A classifier identifies a low-prevalence pest event from sensor
features. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Use probability metrics and fold-safe imbalance handling, not accuracy
alone. The important point is that the estimator is not allowed to
redefine the scientific question after performance results are visible.

The main failure mode is a majority-class model appearing excellent
because prevalence is low. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report PR-AUC, recall, specificity, calibration, and threshold rule. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 22: Instrument transfer

A spectroscopy model is trained on one instrument and deployed on
another. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Instrument identity should define an external validation domain. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is pooling both instruments before random
splitting. A defensible workflow stores the split or resampling
geometry, fits all learned transformations only on analysis rows, and
evaluates the relevant quantities on held-out observations. Report
calibration transfer separately from within-instrument accuracy. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 23: Repeated greenhouse measurements

The same pot is measured repeatedly during growth. In a `sciModelFlowR`
analysis, the first step is to translate this situation into an explicit
prediction target and a validation unit. Pot or plant identity must stay
within one fold when the target is a new experimental unit. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is repeated rows making assessment observations
near-duplicates of training observations. A defensible workflow stores
the split or resampling geometry, fits all learned transformations only
on analysis rows, and evaluates the relevant quantities on held-out
observations. Report unit-level grouping and the number of independent
units per fold. The evidence should be reported together with the model
family, backend, probability or response scale, warnings, seed, and
manifest hash. This keeps the result interpretable even if a different
backend is evaluated later.

#### Extended scenario 24: Multi-output quality prediction

A model predicts several correlated laboratory traits from the same
spectra. In a `sciModelFlowR` analysis, the first step is to translate
this situation into an explicit prediction target and a validation unit.
Each response and the multivariate evaluation rule must be declared. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is averaging target-specific errors without
documenting the scale or weighting. A defensible workflow stores the
split or resampling geometry, fits all learned transformations only on
analysis rows, and evaluates the relevant quantities on held-out
observations. Report metrics by target before any aggregate summary. The
evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 25: Genotype prediction across environments

A breeding study uses genotype and environment descriptors to predict
yield in environments not used for model fitting. In a `sciModelFlowR`
analysis, the first step is to translate this situation into an explicit
prediction target and a validation unit. Environment must define an
external or grouped validation domain before algorithm comparison. The
important point is that the estimator is not allowed to redefine the
scientific question after performance results are visible.

The main failure mode is randomly mixing records from the same
environment across folds. A defensible workflow stores the split or
resampling geometry, fits all learned transformations only on analysis
rows, and evaluates the relevant quantities on held-out observations.
Report environment-wise errors and compare them with the pooled metric.
The evidence should be reported together with the model family, backend,
probability or response scale, warnings, seed, and manifest hash. This
keeps the result interpretable even if a different backend is evaluated
later.

#### Extended scenario 26: Soil property mapping

A soil model predicts organic carbon from terrain and remote-sensing
covariates at sampled coordinates. In a `sciModelFlowR` analysis, the
first step is to translate this situation into an explicit prediction
target and a validation unit. Spatial blocks or location-aware folds
should represent geographic transfer. The important point is that the
estimator is not allowed to redefine the scientific question after
performance results are visible.

The main failure mode is neighbor leakage caused by random row-wise
cross-validation. A defensible workflow stores the split or resampling
geometry, fits all learned transformations only on analysis rows, and
evaluates the relevant quantities on held-out observations. Map held-out
residuals and summarize spatial separation of training and assessment
points. The evidence should be reported together with the model family,
backend, probability or response scale, warnings, seed, and manifest
hash. This keeps the result interpretable even if a different backend is
evaluated later.

### 1.0.0 consolidation note

In the 1.0.0 Consolidated Scientific Release, this workflow keeps the
same scientific semantics established during development. The public
function contract is frozen from 0.9.0; final certification changes
evidence and backend status, not the design, leakage, uncertainty, or
provenance rules taught in this vignette.
