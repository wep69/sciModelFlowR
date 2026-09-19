# Complete Design-Aware Scientific Modeling Workflow

## 1. Purpose

This vignette integrates the package from the scientific question
through tuning and benchmarking. It is intentionally not a catalogue of
independent functions. Each stage creates information required by the
next stage and defines what later results are allowed to mean.

The workflow is written for researchers who need to move from a raw
scientific dataset to a reproducible model-development record while
keeping design, leakage prevention, validation geometry, uncertainty,
calibration, tuning, and model comparison visible.

The sequence is:

**question -\> estimand/prediction target -\> design -\> audit -\>
protected external evidence -\> development resampling -\> preprocessing
-\> feature learning -\> baseline -\> supervised/probabilistic modeling
-\> imbalance/calibration -\> tuning -\> nested validation -\> benchmark
-\> diagnostics -\> report -\> manifest.**

## 2. Learning objectives

After completing the workflow, the reader should be able to define data
roles before modeling, audit common leakage risks, map experimental
hierarchy to resampling, fit preprocessing only in analysis partitions,
use frozen Gold data for software validation, compare deterministic and
probabilistic outputs, handle class imbalance without altering
assessment prevalence, tune hyperparameters without touching final test
labels, distinguish inner selection from outer generalization
performance, benchmark candidates on identical splits, and preserve
every major decision in portable specifications and manifests.

## 3. Step 1: formulate the claim

Before opening R, write the intended claim in a form that implies a
validation domain. “Predict yield” is incomplete. “Predict yield for
plots from the same experimental population” differs from “predict yield
on a new farm next season.” The first may allow plot-level development
splits under an appropriate design; the second requires stronger farm or
temporal separation.

A scientific workflow becomes easier to audit when the claim names the
future unit, response, decision horizon, and intended deployment domain.

## 4. Step 2: load a teaching dataset

``` r

library(sciModelFlowR)

d <- smf_load_dataset("gold_multiclass_imbalanced")
smf_dataset_card("gold_multiclass_imbalanced")
```

Gold datasets are frozen software-validation fixtures. They are not
field evidence. Their purpose is to let users and maintainers test
workflow behavior against documented generators, schemas, properties,
and hashes.

## 5. Step 3: declare data and task roles

``` r

task <- smf_task_spec(
  kind = "multiclass",
  target = "class"
)

predictors <- grep("^x", names(d), value = TRUE)

data_spec <- smf_data_spec(
  target = "class",
  predictors = predictors,
  id_column = "id"
)
```

The explicit target prevents accidental predictor inclusion. Stable row
IDs allow split manifests to survive changes in row order and support
cross-language fixtures.

## 6. Step 4: declare design

``` r

design <- smf_design_spec(id_column = "id")
```

A real agronomic study may additionally declare farm, block, plant,
repeated unit, date, coordinates, or external domain. The design
declaration should correspond to actual randomization or sampling
structure rather than a convenient grouping chosen after model fitting.

## 7. Step 5: audit before modeling

``` r

audit <- smf_audit_data(d, data_spec, design)
audit
```

Inspect missingness, duplicated IDs, duplicated rows, cardinality,
potential target copies, suspicious identifier predictors, and other
quality flags. A blocking leakage warning is not something to average
away with cross-validation.

## 8. Step 6: define the development boundary

If a genuinely external site, season, instrument, or population is
available, protect it before tuning. The final test domain should not be
repeatedly inspected during feature selection, model-family choice,
calibration, threshold optimization, or hyperparameter search.

For an ordinary development example:

``` r

dev_split <- smf_holdout_split(
  d,
  train_prop = 0.80,
  strata = "class",
  id_column = "id",
  seed = 500
)

development <- d[dev_split@train_index, , drop = FALSE]
final_test <- d[dev_split@test_index, , drop = FALSE]
attr(final_test, "smf_partition_role") <- "final_test"
```

The attribute is an additional guard. The stronger safeguard is
procedural: final-test labels are absent from all managed tuning calls.

## 9. Step 7: preprocessing contract

``` r

prep <- smf_preprocess_spec(
  impute_numeric = "median",
  center = TRUE,
  scale = TRUE,
  one_hot = TRUE
)
```

This specification describes intended transformations, not fitted means
or standard deviations. Those quantities are learned separately inside
each analysis partition.

## 10. Step 8: resampling geometry

``` r

inner_rs <- smf_resampling_spec(
  method = "kfold",
  n_splits = 5,
  strata = "class",
  seed = 501
)
```

Replace ordinary folds with grouped, blocked, temporal, spatial, or
external resampling when the design requires it. The resampling method
defines the scientific generalization question and cannot be chosen
solely from software convenience.

## 11. Step 9: baseline model

A baseline answers whether additional complexity provides material
value.

``` r

baseline_model <- smf_model_spec(
  family = "multinomial_regression",
  engine = "tidymodels",
  parameters = list(model_engine = "nnet")
)
```

For a binary task, a `stats` logistic regression provides a
dependency-light reference. For regression,
[`stats::lm()`](https://rdrr.io/r/stats/lm.html) serves the same
architectural purpose. Baselines should be retained in benchmarking
rather than discarded after a more complex learner is introduced.

## 12. Step 10: probabilistic targets

``` r

prob <- smf_probabilistic_spec(
  objective = "class_probability",
  scores = c("log_loss", "brier", "ece")
)
```

A probabilistic classifier should not be evaluated only after hard
thresholding. Proper scores and calibration diagnostics retain
information about forecast confidence.

## 13. Step 11: imbalance handling

``` r

imb <- smf_imbalance_spec(
  method = "weights"
)
```

Weights or synthetic sampling belong inside analysis folds. The
assessment fold should preserve the prevalence relevant to the intended
deployment domain unless the scientific question explicitly defines a
different target distribution.

## 14. Step 12: calibration

``` r

cal <- smf_calibration_spec(
  method = "multinomial",
  source = "analysis_holdout",
  calibration_prop = 0.20
)
```

Calibration is learned from development information. Final test labels
must remain unavailable. The same rule applies to threshold
optimization.

## 15. Step 13: compose an experiment

``` r

experiment <- smf_experiment_spec(
  task = task,
  data = data_spec,
  design = design,
  preprocessing = prep,
  resampling = inner_rs,
  model = baseline_model,
  probabilistic = prob,
  calibration = cal,
  imbalance = imb,
  metrics = list(
    smf_metric_spec("log_loss", "minimize"),
    smf_metric_spec("brier", "minimize")
  ),
  reproducibility = smf_reproducibility_spec(seed = 502)
)
```

`ExperimentSpec` is the composition root. Serializing it records the
intended analysis independently of fitted backend objects.

## 16. Step 14: resampled baseline performance

``` r

resamples <- smf_make_resampler(
  development,
  inner_rs,
  design,
  task
)

baseline_cv <- smf_resample_experiment(
  experiment,
  development,
  resamples = resamples
)
```

Each fold refits preprocessing and any supervised feature operation.
This prevents information learned from the assessment fold from
contaminating the analysis fold.

## 17. Step 15: define the candidate learner

``` r

boost_model <- smf_model_spec(
  family = "boosted_tree",
  engine = "tidymodels",
  parameters = list(model_engine = "xgboost")
)
```

Optional engines remain in `Suggests`; loading the package does not
require them. The model specification describes the backend and
parameters while package-native result objects carry common provenance
and scientific semantics.

## 18. Step 16: define the search space

``` r

space <- smf_search_space(
  model_args.trees = smf_param_int(100, 1200, log = TRUE, resource = TRUE),
  model_args.tree_depth = smf_param_int(2, 10),
  model_args.learn_rate = smf_param_dbl(0.01, 0.30, log = TRUE),
  model_args.loss_reduction = smf_param_dbl(0, 10),
  model_args.sample_size = smf_param_dbl(0.50, 1.00)
)
```

Search ranges should be wide enough to represent plausible behavior but
narrow enough to reflect scientifically and computationally meaningful
configurations. Record why unusual bounds were chosen.

## 19. Step 17: define tuning

``` r

tuning <- smf_tuning_spec(
  method = "bayesian",
  budget = 35,
  inner_resampling = inner_rs,
  objectives = list(smf_metric_spec("log_loss", "minimize")),
  seed = 503,
  parameters = list(initial = 8, candidate_pool = 1024)
)
```

The search budget is part of reproducibility. The selected configuration
should never be reported without the procedure that selected it.

## 20. Step 18: tune only on development data

``` r

boost_experiment <- smf_experiment_spec(
  task = task,
  data = data_spec,
  design = design,
  preprocessing = prep,
  resampling = inner_rs,
  model = boost_model,
  probabilistic = prob,
  calibration = cal,
  imbalance = imb,
  metrics = list(smf_metric_spec("log_loss", "minimize")),
  tuning = tuning,
  reproducibility = smf_reproducibility_spec(seed = 504)
)

search_result <- smf_tune(
  boost_experiment,
  development,
  search_space = space,
  tuning = tuning
)
```

Inspect `search_result@archive`. The archive is evidence about the
development landscape. A single selected row does not reveal whether
many configurations were practically equivalent, whether the optimum
lies at a boundary, or whether failures cluster in one part of the
space.

## 21. Step 19: nested validation

When an unbiased estimate of the development procedure is required, use
outer resampling.

``` r

outer_rs <- smf_resampling_spec(
  method = "kfold",
  n_splits = 5,
  strata = "class",
  seed = 505
)

nested_result <- smf_nested_tune(
  boost_experiment,
  development,
  search_space = space,
  tuning = tuning,
  outer = outer_rs,
  inner = inner_rs
)
```

The result separates `selection_scores` from `generalization_scores`.
The former come from inner resampling and support configuration choice.
The latter come from outer assessment folds and estimate the full
selection procedure.

## 22. Step 20: multi-objective model development

Suppose discrimination and calibration both matter. Define both
objectives instead of optimizing one and mentioning the other afterward.

``` r

multi_tune <- smf_tuning_spec(
  method = "random",
  budget = 60,
  objectives = list(
    smf_metric_spec("log_loss", "minimize"),
    smf_metric_spec("ece", "minimize")
  ),
  seed = 506
)
```

Without a decision rule, the correct output is a Pareto set. If a
deployment team requires one configuration, encode its operational
preferences explicitly.

## 23. Step 21: benchmark on identical folds

A benchmark should compare candidate procedures under the same split
geometry.

``` r

bench <- smf_benchmark_spec(
  candidates = list(
    baseline = baseline_model,
    boosted = boost_model
  ),
  metrics = list(
    smf_metric_spec("log_loss", "minimize"),
    smf_metric_spec("brier", "minimize")
  ),
  resampling = outer_rs,
  decision_rule = NULL,
  seed = 507
)

benchmark_result <- smf_benchmark(
  experiment,
  development,
  benchmark = bench
)
```

With `decision_rule = NULL`, no universal winner is emitted. The result
contains performance summaries, uncertainty, compute information,
fold-level rank stability, and a Pareto representation when multiple
objectives are present.

## 24. Step 22: explicit benchmark decisions

A decision rule can be applied after reviewing the evidence.

``` r

chosen <- smf_decide_benchmark(
  benchmark_result,
  list(
    type = "weighted_sum",
    weights = c(log_loss = 0.75, brier = 0.25)
  )
)
```

This rule is an explicit preference statement. It should not be
described as an objective discovery that one algorithm is universally
best.

## 25. Step 23: final external evaluation

Only after the development procedure is frozen should the final test
labels be used. The final fit uses the selected pipeline on the full
development set and predicts the protected final test.

The exact code depends on whether the final choice came from a
single-objective tune, a Pareto compromise, or a benchmark decision.
Preserve the selected configuration and its hash before opening the test
labels.

## 26. Step 24: diagnostics

Predictive performance does not replace diagnostics. Inspect residual
structure for regression, probability calibration for classification,
subgroup performance when scientifically justified, failure cases, and
whether the model behaves plausibly near the boundaries of the observed
predictor space.

## 27. Step 25: uncertainty

Separate uncertainty in fitted parameters, predictions, resampling
performance, bootstrap statistics, and model-selection procedures. A
standard deviation across folds is not a prediction interval. A
bootstrap interval for a metric is not a Bayesian credible interval.
Type the uncertainty according to what was actually resampled or
modeled.

## 28. Step 26: provenance and manifests

``` r

smf_to_json(experiment)
smf_resample_manifest(resamples)
smf_rng_info()
smf_doctor()
```

Record package version, backend version, R version, data hash, split
hashes, specification hash, search budget, tuning archive, warnings, and
final decision rule. Reproducibility is easier when these objects are
generated automatically than when reconstructed from prose after
publication.

## 29. Step 27: publication reporting

A methods section should explain the study design before the algorithm.
Report the experimental or observational unit, data partitioning rule,
development versus final-test boundary, preprocessing, feature learning,
imbalance correction, calibration, inner resampling, search space,
tuning algorithm, budget, objective metrics, outer validation when used,
benchmark candidates, explicit decision rule, final external evaluation,
and software versions.

Results should distinguish descriptive sample summaries from resampling
estimates and final external performance. Do not use the minimum
inner-CV error as the headline final estimate.

## 30. Step 28: review questions

Before submission, ask whether each reported number has a clear source:
training fit, inner selection, outer generalization, bootstrap
distribution, calibration set, or final test. If the source is
ambiguous, the numerical result is difficult to interpret
scientifically.

Also ask whether any decision was changed after looking at evidence that
was described as final. If so, relabel that evidence as development
information and protect a new validation layer if a confirmatory claim
is required.

## 31. End-to-end pseudocode

``` text
state scientific question
  -> declare target and future unit
  -> declare design and data roles
  -> protect external/final evidence
  -> audit development data
  -> choose design-aware resampling
  -> fit preprocessing inside analysis folds
  -> learn features inside analysis folds
  -> establish baseline
  -> define deterministic/probabilistic outputs
  -> handle imbalance inside analysis folds
  -> calibrate without final labels
  -> define hyperparameter search space
  -> tune inside inner resampling
  -> inspect archive/Pareto set
  -> estimate selection procedure with outer resampling
  -> benchmark candidate procedures on identical folds
  -> apply explicit decision rule only if required
  -> freeze selected procedure
  -> evaluate protected external evidence once
  -> diagnose and quantify uncertainty
  -> report limitations and provenance
```

## 32. Applied case studies

### Case study 1. Field trial with plots nested within farms

The scientific claim is transfer to new farms. Farm IDs define the outer
validation unit. Plot-level random CV is prohibited for the headline
claim. Inner tuning remains inside outer analysis farms, and
preprocessing is refitted in every inner split.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 2. Repeated plant phenotyping

Multiple images from each plant are observations of the same biological
unit. Plant IDs must remain intact through feature selection, tuning,
and calibration. A model that performs well only because images of the
same plant occur on both sides of a split does not estimate new-plant
generalization.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 3. Soil spectroscopy across instruments

Instrument identity can be a major domain shift. Keep at least one
instrument external if instrument transfer is the claim. Latent
representations and wavelength selection must be learned on development
instruments only.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 4. Weather-to-yield forecasting

Temporal order defines availability. Use rolling or expanding windows.
Hyperparameters selected with future years leaked into inner folds can
encode a future climate regime and exaggerate forecast performance.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 5. Spatial digital soil mapping

Coordinates reveal local dependence. Spatial blocks or buffers should
replace ordinary random folds. The outer geometry should approximate the
spatial extrapolation or interpolation question stated in the
manuscript.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 6. Rare disease detection

Class balancing occurs only in analysis folds. Probability calibration
and threshold selection use development predictions. Final prevalence is
preserved in assessment data so calibration and utility can be
interpreted for deployment.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 7. Multiclass nutrient deficiency

Macro-F1, log loss, class-specific recall, and calibration can disagree.
Preserve several objectives when necessary. A Pareto front is more
transparent than a single accuracy-based ranking.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 8. Remote-sensing transfer across seasons

Seasonal acquisition differences can cause domain shift. If next-season
use is intended, reserve the latest season or use temporal outer folds.
Random pixel splits mainly estimate interpolation among known
acquisition conditions.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 9. Growth-model surrogate prediction

A flexible learner may predict well while violating known biological
monotonicity or saturation behavior. Benchmark performance together with
diagnostics and scientific plausibility; a leaderboard cannot encode
every biological constraint.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 10. Compute-constrained extension service

Operational latency may matter alongside error. Treat compute as a
declared benchmark attribute or objective rather than quietly preferring
a smaller model after seeing results. The compromise rule should be
reproducible.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 11. Cross-study validation

When several independent studies exist, study-level outer folds estimate
transfer better than pooled random CV. Inner tuning can use studies in
each analysis set while the held-out study remains completely unseen.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

### Case study 12. Small-sample experiment

Restrict model families and hyperparameter domains. Repeated
design-aware validation and simple baselines are often more informative
than a very large search budget. The amount of evidence is limited by
the experiment, not by available CPU time.

**Workflow audit.** Identify the independent unit, protected domain,
resampling geometry, fold-trained operations, selection metric,
uncertainty target, and evidence that would be considered external. Then
ask whether the same claim would remain defensible if the
best-performing algorithm name changed.

## 33. Minimum release checklist for an analysis

Scientific question and target population stated.

Experimental or observational unit declared.

IDs, groups, blocks, repeated units, time, space, and external domains
documented.

Data audit reviewed before model fitting.

Final evidence protected before model development.

Preprocessing fitted only within analysis partitions.

Supervised feature learning fitted only within analysis partitions.

Resampling geometry matches the intended generalization claim.

Baseline retained.

Probability metrics used when probability quality matters.

Imbalance correction kept inside analysis data.

Calibration and threshold selection separated from final test labels.

Search space and tuning budget documented.

Nested validation used when unbiased selection-procedure performance is
required.

Multi-objective tradeoffs preserved before compromise.

Benchmark candidates evaluated on identical folds.

No universal winner emitted without an explicit rule.

Diagnostics reviewed.

Uncertainty type labeled correctly.

Data, spec, split, and package provenance retained.

Limitations on external validity reported.

## 34. Final perspective

The complete workflow is not a long sequence because every analysis
requires every method. It is long because scientific modeling contains
several logically distinct decisions that should not be hidden inside
one automated fitting call. Simple studies can stop after audit,
design-aware resampling, a baseline model, diagnostics, and a manifest.
More complex studies can add feature selection, probabilistic
prediction, calibration, tuning, or benchmarking only when each addition
answers a stated problem.

The mature grammar remains stable:

**design before algorithm; information boundaries before optimization;
diagnostics before interpretation; typed uncertainty before claims;
explicit preferences before model ranking; external evidence after
development; provenance throughout.**

#### Reproducibility lab 1: Audit the information boundary

Take one complete analysis and label every object as raw data,
development-only state, fold-specific state, calibration state,
outer-assessment evidence, or final-test evidence. Verify that no object
moves backward across the boundary. This exercise often reveals hidden
leakage in apparently clean notebooks. Record the outcome in the
analysis log together with hashes and any warnings. The purpose is not
to force numerical identity across all hardware but to identify which
scientific conclusions are stable to defensible workflow choices.

#### Reproducibility lab 1: Re-run with a different validation geometry

Compare random, grouped, temporal, or spatial resampling only when each
corresponds to a clearly named claim. Do not interpret the smallest
error as the correct geometry. Instead document how the performance
estimate changes as the generalization task becomes more demanding.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

#### Reproducibility lab 1: Inspect model-selection instability

Repeat the inner tuning seed while freezing the outer folds. Compare
selected configurations and outer predictions. Large hyperparameter
variation with stable predictions suggests an equivalence region;
unstable predictions suggest greater model-development uncertainty.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

#### Reproducibility lab 1: Compare explicit decision rules

Apply two preregistered benchmark rules to the same performance table.
If the preferred model changes, the evidence is preference-sensitive.
Report that dependence instead of describing one candidate as
objectively superior. Record the outcome in the analysis log together
with hashes and any warnings. The purpose is not to force numerical
identity across all hardware but to identify which scientific
conclusions are stable to defensible workflow choices.

#### Reproducibility lab 1: Reproduce from manifests

Start a clean R session and reconstruct the workflow from serialized
specifications, frozen split manifests, dataset hashes, and recorded
seeds. Note which parts require optional backends and verify that absent
backends fail explicitly rather than silently switching algorithms.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

#### Reproducibility lab 2: Audit the information boundary

Take one complete analysis and label every object as raw data,
development-only state, fold-specific state, calibration state,
outer-assessment evidence, or final-test evidence. Verify that no object
moves backward across the boundary. This exercise often reveals hidden
leakage in apparently clean notebooks. Record the outcome in the
analysis log together with hashes and any warnings. The purpose is not
to force numerical identity across all hardware but to identify which
scientific conclusions are stable to defensible workflow choices.

#### Reproducibility lab 2: Re-run with a different validation geometry

Compare random, grouped, temporal, or spatial resampling only when each
corresponds to a clearly named claim. Do not interpret the smallest
error as the correct geometry. Instead document how the performance
estimate changes as the generalization task becomes more demanding.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

#### Reproducibility lab 2: Inspect model-selection instability

Repeat the inner tuning seed while freezing the outer folds. Compare
selected configurations and outer predictions. Large hyperparameter
variation with stable predictions suggests an equivalence region;
unstable predictions suggest greater model-development uncertainty.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

#### Reproducibility lab 2: Compare explicit decision rules

Apply two preregistered benchmark rules to the same performance table.
If the preferred model changes, the evidence is preference-sensitive.
Report that dependence instead of describing one candidate as
objectively superior. Record the outcome in the analysis log together
with hashes and any warnings. The purpose is not to force numerical
identity across all hardware but to identify which scientific
conclusions are stable to defensible workflow choices.

#### Reproducibility lab 2: Reproduce from manifests

Start a clean R session and reconstruct the workflow from serialized
specifications, frozen split manifests, dataset hashes, and recorded
seeds. Note which parts require optional backends and verify that absent
backends fail explicitly rather than silently switching algorithms.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

#### Reproducibility lab 3: Audit the information boundary

Take one complete analysis and label every object as raw data,
development-only state, fold-specific state, calibration state,
outer-assessment evidence, or final-test evidence. Verify that no object
moves backward across the boundary. This exercise often reveals hidden
leakage in apparently clean notebooks. Record the outcome in the
analysis log together with hashes and any warnings. The purpose is not
to force numerical identity across all hardware but to identify which
scientific conclusions are stable to defensible workflow choices.

#### Reproducibility lab 3: Re-run with a different validation geometry

Compare random, grouped, temporal, or spatial resampling only when each
corresponds to a clearly named claim. Do not interpret the smallest
error as the correct geometry. Instead document how the performance
estimate changes as the generalization task becomes more demanding.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

#### Reproducibility lab 3: Inspect model-selection instability

Repeat the inner tuning seed while freezing the outer folds. Compare
selected configurations and outer predictions. Large hyperparameter
variation with stable predictions suggests an equivalence region;
unstable predictions suggest greater model-development uncertainty.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

#### Reproducibility lab 3: Compare explicit decision rules

Apply two preregistered benchmark rules to the same performance table.
If the preferred model changes, the evidence is preference-sensitive.
Report that dependence instead of describing one candidate as
objectively superior. Record the outcome in the analysis log together
with hashes and any warnings. The purpose is not to force numerical
identity across all hardware but to identify which scientific
conclusions are stable to defensible workflow choices.

#### Reproducibility lab 3: Reproduce from manifests

Start a clean R session and reconstruct the workflow from serialized
specifications, frozen split manifests, dataset hashes, and recorded
seeds. Note which parts require optional backends and verify that absent
backends fail explicitly rather than silently switching algorithms.
Record the outcome in the analysis log together with hashes and any
warnings. The purpose is not to force numerical identity across all
hardware but to identify which scientific conclusions are stable to
defensible workflow choices.

## Appendix A. End-to-end audit stations

### A.1. Question and estimand

Rewrite the scientific objective in one sentence that names the
response, future unit, domain, and decision scale. Then verify that the
chosen metric actually evaluates a consequence relevant to that
statement. Finish the station by writing one sentence that would belong
in a Methods section and one sentence that would belong in a limitations
paragraph. This forces the computational choice to be translated into a
scientific claim and its boundary.

### A.2. Data identity

Confirm file identity, row IDs, units, factor levels, missing-value
codes, and any preprocessing performed before the package sees the data.
Undocumented upstream transformations are part of the analysis and
should be included in provenance. Finish the station by writing one
sentence that would belong in a Methods section and one sentence that
would belong in a limitations paragraph. This forces the computational
choice to be translated into a scientific claim and its boundary.

### A.3. Experimental unit

Trace randomization or sampling hierarchy from field, farm, plant, plot,
subject, image, spectrum, or time point. Verify that the number of rows
is not being mistaken for the number of independent replicates. Finish
the station by writing one sentence that would belong in a Methods
section and one sentence that would belong in a limitations paragraph.
This forces the computational choice to be translated into a scientific
claim and its boundary.

### A.4. Leakage screen

List variables that might encode the target, future information,
treatment assignment, post-outcome measurements, or acquisition
artifacts. Document why each retained predictor would genuinely be
available at prediction time. Finish the station by writing one sentence
that would belong in a Methods section and one sentence that would
belong in a limitations paragraph. This forces the computational choice
to be translated into a scientific claim and its boundary.

### A.5. Development boundary

Identify which observations can influence model-family choice,
preprocessing, feature learning, tuning, calibration, and thresholds.
Identify a separate evidence layer that remains untouched until the
procedure is frozen. Finish the station by writing one sentence that
would belong in a Methods section and one sentence that would belong in
a limitations paragraph. This forces the computational choice to be
translated into a scientific claim and its boundary.

### A.6. Resampling geometry

State what one assessment fold represents scientifically. If that
sentence does not match the intended deployment unit, redesign the split
before fitting more complex models. Finish the station by writing one
sentence that would belong in a Methods section and one sentence that
would belong in a limitations paragraph. This forces the computational
choice to be translated into a scientific claim and its boundary.

### A.7. Preprocessing state

For every imputation, scaling, encoding, or transformation, identify the
rows used to estimate its parameters. Verify that assessment data are
transformed using stored state and are never used to refit it. Finish
the station by writing one sentence that would belong in a Methods
section and one sentence that would belong in a limitations paragraph.
This forces the computational choice to be translated into a scientific
claim and its boundary.

### A.8. Feature learning

For every supervised selection or representation step, verify that the
outcome information comes only from analysis rows. Confirm that PCA,
PLS, selected variables, and feature maps are stored and reapplied
without assessment refitting. Finish the station by writing one sentence
that would belong in a Methods section and one sentence that would
belong in a limitations paragraph. This forces the computational choice
to be translated into a scientific claim and its boundary.

### A.9. Baseline adequacy

Inspect whether a simple reference procedure already captures most
predictable structure. A complex learner should solve a demonstrated
limitation rather than merely provide a more modern algorithm name.
Finish the station by writing one sentence that would belong in a
Methods section and one sentence that would belong in a limitations
paragraph. This forces the computational choice to be translated into a
scientific claim and its boundary.

### A.10. Probability quality

When predictions are probabilistic, inspect proper scores, calibration,
sharpness, and class-specific behavior. Hard labels alone discard
information needed for risk-sensitive decisions. Finish the station by
writing one sentence that would belong in a Methods section and one
sentence that would belong in a limitations paragraph. This forces the
computational choice to be translated into a scientific claim and its
boundary.

### A.11. Imbalance operations

Trace weights, downsampling, upsampling, or synthetic sampling to the
analysis fold. Ensure that assessment and final-test distributions
retain the prevalence needed for interpretation. Finish the station by
writing one sentence that would belong in a Methods section and one
sentence that would belong in a limitations paragraph. This forces the
computational choice to be translated into a scientific claim and its
boundary.

### A.12. Calibration boundary

Identify the data used to fit the calibrator and any threshold. Verify
that those data are distinct from the final evidence used for the
headline performance claim. Finish the station by writing one sentence
that would belong in a Methods section and one sentence that would
belong in a limitations paragraph. This forces the computational choice
to be translated into a scientific claim and its boundary.

### A.13. Tuning archive

Review the complete archive for failures, flat regions, boundary
solutions, compute cost, and unstable rankings. Document why the
selected configuration is acceptable beyond having the numerically best
development score. Finish the station by writing one sentence that would
belong in a Methods section and one sentence that would belong in a
limitations paragraph. This forces the computational choice to be
translated into a scientific claim and its boundary.

### A.14. Nested validation

Compare inner selection scores with outer generalization estimates.
Treat differences as evidence about selection optimism and workflow
variability, not as a reason to alter the outer folds after inspection.
Finish the station by writing one sentence that would belong in a
Methods section and one sentence that would belong in a limitations
paragraph. This forces the computational choice to be translated into a
scientific claim and its boundary.

### A.15. Benchmark fairness

Verify that candidate procedures use identical resampling geometry and
comparable development information. Report search budgets and compute so
that performance differences are not confused with unequal optimization
effort. Finish the station by writing one sentence that would belong in
a Methods section and one sentence that would belong in a limitations
paragraph. This forces the computational choice to be translated into a
scientific claim and its boundary.

### A.16. Decision rule

If one candidate is chosen from several objectives, state the explicit
rule and preference weights. Recalculate the decision under at least one
reasonable alternative to assess preference sensitivity. Finish the
station by writing one sentence that would belong in a Methods section
and one sentence that would belong in a limitations paragraph. This
forces the computational choice to be translated into a scientific claim
and its boundary.

### A.17. Final evaluation

Open protected final labels only after the procedure is frozen. Record
the exact selected configuration and hashes before evaluation. Do not
re-enter development without acknowledging that the test set has been
consumed. Finish the station by writing one sentence that would belong
in a Methods section and one sentence that would belong in a limitations
paragraph. This forces the computational choice to be translated into a
scientific claim and its boundary.

### A.18. Diagnostics

Inspect model-specific residual, probability, subgroup, temporal, or
spatial diagnostics. A high average score does not prove that the fitted
process is scientifically plausible across the whole domain. Finish the
station by writing one sentence that would belong in a Methods section
and one sentence that would belong in a limitations paragraph. This
forces the computational choice to be translated into a scientific claim
and its boundary.

### A.19. Uncertainty labeling

For every interval or standard error, identify what source of variation
it represents. Avoid using the generic word uncertainty when the object
actually describes only fold variation, bootstrap variation, posterior
variation, or conditional predictive variation. Finish the station by
writing one sentence that would belong in a Methods section and one
sentence that would belong in a limitations paragraph. This forces the
computational choice to be translated into a scientific claim and its
boundary.

### A.20. Reproducibility package

Assemble dataset hashes, specifications, split manifests, tuning
archives, benchmark tables, warnings, session information, package
versions, and validation status. Another analyst should be able to
distinguish what was implemented from what was numerically certified.
Finish the station by writing one sentence that would belong in a
Methods section and one sentence that would belong in a limitations
paragraph. This forces the computational choice to be translated into a
scientific claim and its boundary.

## Appendix B. One final reproducibility rule

The workflow is complete only when another analyst can identify which
data were development data, which observations supplied final evidence,
which transformations were learned in each partition, which
model-selection rule was used, and which software state produced the
reported numbers. Reproducibility therefore includes both executable
artifacts and scientific role labels. A perfectly reproducible analysis
with an invalid validation boundary remains scientifically weak; a
scientifically sound design without preserved code and manifests remains
difficult to verify. `sciModelFlowR` treats both dimensions as part of
the same release contract.
