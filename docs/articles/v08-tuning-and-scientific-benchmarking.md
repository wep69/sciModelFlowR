# Scientific Tuning, Nested Model Selection, and Hyperparameter Search

## 1. Why tuning is a scientific workflow problem

Hyperparameter tuning is often introduced as an optimization problem:
define a search space, evaluate configurations, and keep the one with
the smallest error. That description is computationally correct but
scientifically incomplete. The estimate used to choose a configuration
is itself a random quantity determined by the resampling design,
preprocessing boundary, feature-selection boundary, outcome prevalence,
grouping structure, temporal ordering, spatial separation, random seeds,
and the metric used for selection. A tuning result is therefore
inseparable from the validation geometry that produced it.

`sciModelFlowR` 0.4.0 treats tuning as a layer inside the scientific
workflow rather than a separate leaderboard. The package preserves three
distinctions throughout this vignette. First, **development data are
different from final test data**. Second, **selection performance is
different from generalization performance**. Third, **one metric is not
automatically a universal scientific utility function**. These
distinctions determine which data may enter optimization and what claims
can be made after optimization.

The basic sequence is:

**design -\> audit -\> development resampling -\> fold-safe
preprocessing/features -\> hyperparameter search -\> configuration
selection -\> outer or external validation -\> diagnostics -\>
scientific reporting.**

## 2. Learning objectives

After completing this vignette, the reader should be able to:

1.  define numeric, integer, categorical, logical, and conditional
    search spaces;
2.  understand why tuning the final test set causes optimistic
    performance estimates;
3.  choose between grid, random, racing, Bayesian optimization,
    successive halving, and Hyperband;
4.  distinguish inner resampling used for model selection from outer
    resampling used for generalization estimation;
5.  define single- and multi-objective tuning targets with explicit
    directions;
6.  inspect a tuning archive instead of treating the selected
    configuration as the only result;
7.  interpret a Pareto set without forcing a universal winner;
8.  apply an explicit compromise rule when a single configuration is
    operationally required;
9.  preserve preprocessing, imbalance handling, calibration, and feature
    learning inside the appropriate analysis partitions;
10. record search budgets, split hashes, compute cost, and decision
    rules for reproducibility.

## 3. SearchSpace is a scientific contract

A search space should encode only configurations that make sense for the
intended model. It is not simply a rectangle of arbitrary numbers. Some
parameters are continuous, some are integers, some are factors, and some
are active only when another parameter has a particular value.

``` r

library(sciModelFlowR)

space <- smf_search_space(
  nrounds = smf_param_int(50, 800, log = TRUE, resource = TRUE),
  params.eta = smf_param_dbl(0.01, 0.30, log = TRUE),
  params.max_depth = smf_param_int(2, 10),
  params.subsample = smf_param_dbl(0.50, 1.00),
  params.booster = smf_param_fct(c("gbtree", "dart")),
  params.rate_drop = smf_param_dbl(
    0.0, 0.5,
    depends_on = list(param = "params.booster", values = "dart")
  )
)
```

The dotted parameter names are deliberate. They describe paths inside
`ModelSpec@parameters`. For example, `params.max_depth` becomes
`model@parameters$params$max_depth`, whereas `nrounds` is stored at the
top level. This allows the same search-space object to update nested
backend parameters without exposing backend objects as the package API.

Conditionality matters scientifically because a parameter should not be
assigned a value when the corresponding mechanism is inactive. In the
example, dropout rate has no meaning for the ordinary tree booster.
[`smf_search_grid()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md)
and
[`smf_search_random()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md)
therefore mark inactive parameters as `NA` instead of pretending that
every configuration uses every dimension.

## 4. Grid search

Grid search evaluates a finite Cartesian product. It is transparent and
reproducible, but its cost increases exponentially with dimension. It is
most defensible when the number of parameters is small and the grid has
scientific meaning.

``` r

grid <- smf_search_grid(space, levels = 4, max_size = 5000)
head(grid)
```

A coarse grid can be useful for pedagogical demonstrations and
sensitivity analysis. It is less attractive when several continuous
parameters interact because many evaluations are spent at uninformative
corners of the search region.

``` r

tune_grid <- smf_tuning_spec(
  method = "grid",
  budget = 80,
  inner_resampling = smf_resampling_spec("kfold", n_splits = 5, seed = 401),
  objectives = list(smf_metric_spec("rmse", "minimize")),
  seed = 402
)
```

The `budget` is explicit. A scientific report should disclose it because
comparing a learner given 500 trials against another learner given five
trials is not a neutral algorithm comparison.

## 5. Random search

Random search samples configurations independently from the declared
domains. It often allocates compute more efficiently than a regular grid
when only a subset of dimensions strongly influences performance.

``` r

random_configs <- smf_search_random(space, n = 50, seed = 403)
```

Log-scaled sampling is important for parameters such as learning rates
or regularization penalties. Uniform sampling on the raw scale can
overrepresent large values and undersample orders of magnitude near
zero.

``` r

tune_random <- smf_tuning_spec(
  method = "random",
  budget = 60,
  inner_resampling = smf_resampling_spec("kfold", n_splits = 5, seed = 404),
  objectives = list(smf_metric_spec("rmse", "minimize")),
  seed = 405
)
```

Reusing the seed reproduces the candidate set inside R. Cross-language
equivalence should rely on frozen candidate manifests when exact
R/Python parity is required rather than assuming identical RNG streams.

## 6. The tuning boundary

The most important tuning rule is not an algorithm choice. It is an
information-boundary rule:

**final test labels may not participate in hyperparameter search.**

A final test set is evidence about the selected procedure. Once its
labels affect configuration choice, it becomes development data and
cannot provide an unbiased final estimate for that same procedure.

`sciModelFlowR` managed tuning rejects data explicitly marked with
assessment or final-test roles. More importantly, nested workflows
construct inner folds entirely inside each outer analysis partition.
This design is stronger than relying on analyst memory.

The same boundary applies to transformations. Imputation, scaling,
feature selection, representation learning, class balancing, and
calibration must be fitted at the correct level. If a configuration is
evaluated on an inner assessment fold, every data-dependent operation
used by that configuration must be learned without seeing that fold.

## 7. Metrics and selection objectives

An objective must include both the metric and its optimization
direction.

``` r

objectives <- list(
  smf_metric_spec("rmse", direction = "minimize", decision_role = "selection"),
  smf_metric_spec("mae", direction = "minimize", decision_role = "selection")
)
```

Do not choose a metric only because it is familiar. RMSE penalizes large
residuals strongly. MAE corresponds to absolute-error loss. Log loss
evaluates probabilistic classification and penalizes confident wrong
predictions. PR-oriented measures can be more informative than accuracy
when the positive class is rare. Calibration metrics answer a different
question from discrimination metrics.

The metric used for model selection becomes part of the estimand of the
model-development procedure. Changing it can change the selected
configuration even when every fitted model is identical.

## 8. Racing

Racing avoids spending the full resampling budget on configurations that
accumulate convincing evidence of inferior performance. Version 0.4.0
includes a package-native sequential race. Candidates are evaluated on
common folds. After a minimum number of folds, paired performance
differences are used to eliminate configurations whose evidence
indicates that they are worse than the current leader under the declared
primary objective.

``` r

tune_race <- smf_tuning_spec(
  method = "racing",
  budget = 40,
  inner_resampling = smf_resampling_spec("repeated_kfold", n_splits = 5, n_repeats = 2, seed = 410),
  objectives = list(smf_metric_spec("rmse", "minimize")),
  seed = 411,
  parameters = list(min_folds = 3, alpha = 0.10)
)
```

A racing result should be interpreted as resource allocation, not proof
that eliminated configurations are intrinsically poor. The conclusion is
conditional on the current data, folds, metric, and race settings.

## 9. Bayesian optimization

Bayesian optimization is useful when individual model evaluations are
expensive and the objective surface is sufficiently structured that
previous evaluations can inform where to search next.

The package-native reference implementation uses a Gaussian-process
surrogate over an encoded search space and expected improvement as the
acquisition criterion. It begins with a random initial design, fits the
surrogate to observed objective values, creates a fresh candidate pool,
computes acquisition values, evaluates the most promising proposal, and
repeats until the budget is exhausted.

``` r

tune_bo <- smf_tuning_spec(
  method = "bayesian",
  budget = 30,
  inner_resampling = smf_resampling_spec("kfold", n_splits = 5, seed = 420),
  objectives = list(smf_metric_spec("rmse", "minimize")),
  seed = 421,
  parameters = list(initial = 8, candidate_pool = 1024)
)
```

The package-native implementation is intentionally inspectable. For
highly specialized Bayesian optimization, the R ecosystem provides
`mlr3mbo`, which implements modular surrogate, acquisition, and
optimizer components. Such backends remain optional; package-native
result contracts should still record what was optimized and how. The
existence of an advanced optimizer does not change the scientific
validation boundary.

## 10. Successive halving and Hyperband

Some learners expose a meaningful resource parameter: number of boosting
rounds, number of trees, epochs, iterations, or another monotonically
increasing training budget. Successive halving evaluates many
configurations with a small resource, retains the most promising
fraction, increases resources, and repeats. Hyperband combines multiple
halving brackets with different exploration-versus-resource tradeoffs.

A resource parameter is marked explicitly in the search space.

``` r

space_hb <- smf_search_space(
  nrounds = smf_param_int(25, 800, log = TRUE, resource = TRUE),
  params.eta = smf_param_dbl(0.01, 0.30, log = TRUE),
  params.max_depth = smf_param_int(2, 10)
)

hb <- smf_tuning_spec(
  method = "hyperband",
  budget = 27,
  inner_resampling = smf_resampling_spec("kfold", n_splits = 5, seed = 430),
  objectives = list(smf_metric_spec("rmse", "minimize")),
  seed = 431,
  parameters = list(
    resource_param = "nrounds",
    min_resource = 25,
    max_resource = 800,
    eta = 3
  )
)
```

Resource-aware methods are inappropriate when partial resource values do
not represent meaningful intermediate fits. The resource must correspond
to a training trajectory for which increased budget can reasonably
improve or stabilize the learner.

## 11. Multi-objective tuning

Scientific model selection frequently involves more than one objective.
Examples include prediction error and calibration, sensitivity and
specificity, predictive performance and computation, or error and model
complexity.

``` r

multi <- smf_tuning_spec(
  method = "random",
  budget = 80,
  objectives = list(
    smf_metric_spec("rmse", "minimize"),
    smf_metric_spec("mae", "minimize")
  ),
  seed = 440
)
```

When objectives conflict, `sciModelFlowR` computes a nondominated Pareto
set. A configuration is Pareto dominated when another configuration is
at least as good on every declared objective and strictly better on at
least one.

A Pareto set is often the scientifically correct output. Version 0.4.0
does **not** silently collapse multiple objectives into a universal
winner.

If an operational decision requires one configuration, state the
compromise rule.

``` r

rule <- list(
  type = "weighted_sum",
  weights = c(rmse = 0.7, mae = 0.3)
)
```

Weights are scientific or operational preferences, not data-derived
truths. They belong in the report and provenance record.

## 12. Nested resampling

Nested resampling separates model selection from performance estimation.

Let the outer resampling index be j. Within outer analysis data, an
inner procedure searches configurations and selects one configuration
h_j. That configuration is then refitted using the outer analysis data
and evaluated on outer assessment data that were not used in the inner
search.

The outer score estimates the performance of the **selection
procedure**, not merely the performance of one globally fixed set of
hyperparameters.

``` r

outer <- smf_resampling_spec(
  method = "kfold",
  n_splits = 5,
  seed = 451
)

inner <- smf_resampling_spec(
  method = "kfold",
  n_splits = 4,
  seed = 452
)

nested <- smf_nested_tune(
  spec = experiment,
  data = development_data,
  search_space = space,
  tuning = tune_random,
  outer = outer,
  inner = inner
)
```

The result stores outer split hashes and corresponding inner manifest
hashes. Selection scores and outer generalization scores are separate
fields. This distinction prevents an optimistic inner score from being
mislabeled as final predictive performance.

## 13. A complete tuning workflow

A realistic workflow first creates a development dataset that excludes
the final external domain. It then defines `TaskSpec`, `DataSpec`, and
`DesignSpec`, audits the development data, defines an appropriate inner
resampling geometry, constructs a search space, and tunes only inside
that development boundary.

``` r

d <- smf_load_dataset("gold_multiclass_imbalanced")

task <- smf_task_spec("multiclass", target = "class")
data_spec <- smf_data_spec(
  target = "class",
  predictors = grep("^x", names(d), value = TRUE),
  id_column = "id"
)

design <- smf_design_spec(id_column = "id")

experiment <- smf_experiment_spec(
  task = task,
  data = data_spec,
  design = design,
  preprocessing = smf_preprocess_spec(center = TRUE, scale = TRUE),
  resampling = smf_resampling_spec("kfold", n_splits = 5, seed = 460),
  model = smf_model_spec(
    family = "boosted_tree",
    engine = "tidymodels",
    parameters = list(model_engine = "xgboost")
  ),
  metrics = list(smf_metric_spec("log_loss", "minimize")),
  imbalance = smf_imbalance_spec("weights")
)
```

The example is intentionally backend-optional. The scientific contracts
are inspectable even on a computer where the optional learner is
unavailable.

## 14. Archive-first interpretation

A `TuningResult` stores an archive rather than only a best row. Inspect
the archive for flat regions, unstable configurations, failures,
unexpectedly large compute costs, conditional-parameter behavior, and
whether the selected configuration lies at a search-space boundary.

A boundary optimum is an invitation to ask whether the domain was too
narrow, not automatic evidence that the boundary value is scientifically
ideal. Conversely, endlessly expanding a search region because the best
point remains on the boundary can become post hoc optimization.
Search-space revisions should be versioned and justified.

## 15. Hyperparameter stability

Different resampling seeds can select different configurations even when
their outer performance is nearly identical. This is not necessarily a
defect. It can indicate that the objective surface contains a broad
plateau of equivalent solutions.

For scientific reporting, distinguish configuration stability from
prediction stability. If several hyperparameter combinations yield
indistinguishable predictive behavior, emphasizing one exact combination
can exaggerate certainty.

## 16. Computational accounting

Search algorithms trade compute for information. Record the number of
evaluated configurations, folds per configuration, resource levels for
halving methods, failed fits, elapsed time, backend version, and random
seed.

A comparison between algorithms is scientifically fair only when the
resource allocation is stated. A method given more evaluations has a
larger opportunity to adapt to the development data.

## 17. Common mistake: tuning before deciding the validation geometry

Choosing K-fold by habit and only later noticing repeated plants, field
blocks, years, or spatial locations can invalidate an otherwise
sophisticated optimizer. No acquisition function can repair the wrong
experimental unit.

Use `DesignSpec` first. Then choose grouped, blocked, temporal, spatial,
or external resampling that matches the claim.

## 18. Common mistake: selecting on outer folds

Nested cross-validation fails if the analyst inspects outer results and
modifies the search space, model family, or decision rule repeatedly
until outer performance looks satisfactory. Outer folds then become
another development set.

When substantial decisions are changed after seeing outer results, rerun
the evaluation with a newly protected validation layer or clearly label
the analysis as exploratory.

## 19. Common mistake: universal winner tables

A benchmark table can make one model appear universally superior because
one column is sorted first. Scientific utility is rarely that simple. A
model can have slightly better RMSE but worse calibration, more unstable
performance, greater compute demand, or unacceptable failure modes.

`sciModelFlowR` therefore keeps decision rules explicit. Ranking is a
transformation of evidence under a declared preference rule, not a
property intrinsic to the algorithm name.

## 20. Reporting template

A tuning methods section should state the search-space ranges and
scales, conditional parameters, optimizer, evaluation budget, inner
resampling geometry, preprocessing and feature-learning boundary,
objective metrics and directions, random seeds, handling of failed
configurations, multi-objective compromise rule when used, and whether
an external or outer validation layer remained untouched.

Results should report the selected configuration only together with its
selection context. For nested tuning, report outer generalization
performance as the main estimate of the complete development procedure.
Do not present the best inner-CV value as if it were an unbiased final
performance estimate.

## 21. Scientific checklist

Was design declared before tuning?

Are dependent units kept together when required?

Are temporal and spatial boundaries respected?

Are preprocessing and feature selection refitted inside analysis folds?

Is imbalance correction confined to analysis data?

Is probability calibration separated from final test labels?

Is the tuning metric scientifically aligned with the task?

Is the search budget reported?

Are conditional parameters encoded explicitly?

Is final test evidence absent from search?

Are inner selection and outer generalization scores labeled separately?

Are multiple objectives represented by a Pareto set before any
compromise rule?

Is the compromise rule explicit and reproducible?

Are split and archive hashes retained?

## 22. Function-selection guide

| Question | Start with | Escalate when needed |
|----|----|----|
| Define tunable domains | [`smf_search_space()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md) | conditional `depends_on` rules |
| Inspect a finite grid | [`smf_search_grid()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md) | random search for larger spaces |
| Draw reproducible configurations | [`smf_search_random()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md) | Bayesian optimization for expensive evaluations |
| Tune with full evaluation | `smf_tune(..., method="grid"/"random")` | racing |
| Stop weak configurations early | `method="racing"` | resource-aware halving |
| Allocate explicit training resources | successive halving | Hyperband |
| Learn where to search next | Bayesian optimization | advanced optional ecosystem backend |
| Separate selection from evaluation | [`smf_nested_tune()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md) | external validation after development |
| Preserve conflicting objectives | [`smf_pareto_front()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md) | explicit compromise rule |
| Choose one Pareto solution | [`smf_select_compromise()`](https://wep69.github.io/sciModelFlowR/reference/smf_tuning_api.md) | preregistered utility function |

## 23. Practice cases

### Practice case 1. Nitrogen-response prediction across farms

Plots from the same farm share management history and soil structure.
Define farm-level outer folds when the claim concerns new farms. Inner
tuning must operate only within the outer analysis farms. A random row
split would let farm identity leak through correlated predictors and can
make aggressive tree settings appear more stable than they are.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 2. Hyperspectral disease classification

Spectra from the same leaf are highly correlated. Keep leaf or plant
identifiers together before searching kernels, latent dimensions, or
boosting depth. When spectra are acquired on multiple instruments,
reserve instrument transfer as a separate domain if that is the intended
deployment claim.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 3. Rare pest outbreak forecasting

Accuracy is a poor sole objective when outbreak events are rare. Use
probability-sensitive or PR-oriented metrics, keep prevalence-altering
sampling inside analysis folds, and evaluate calibration on
natural-prevalence assessment data. Threshold choice belongs after
probability modeling and should not contaminate the final test.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 4. Temporal crop-yield forecasting

A shuffled inner CV can look efficient but violates forecasting time.
Use expanding or sliding windows inside each outer temporal window.
Search-space parameters that effectively memorize historical periods
should be judged only on future assessment periods.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 5. Spatial soil-property mapping

Random folds can place neighboring samples on both sides of the split.
Use spatial blocks or buffers. Hyperparameter settings controlling
smoothness or tree complexity can otherwise adapt to short-range spatial
duplication and produce misleadingly optimistic selection scores.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 6. Image models with training epochs

Epochs are a natural resource parameter for halving or Hyperband. A
configuration surviving a low-epoch stage is not yet a final scientific
model; it has only earned more resource under the declared schedule.
External biological units must still remain protected.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 7. Multi-environment cultivar prediction

Environment-level generalization should be encoded in the resampling
design. A Pareto analysis can preserve predictive accuracy and
computational cost without declaring a universal algorithm winner. If
breeders prioritize worst-environment performance, that preference must
be encoded explicitly.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 8. Sensor calibration transfer

When deployment occurs on a new sensor, tuning on pooled sensors can
conceal transfer failure. Use source sensors for inner search and a
genuinely external sensor for final evidence. Calibration transformation
itself must be learned without accessing the external sensor labels.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 9. Count-response modeling

If competing learners optimize deviance while stakeholders care about
absolute count error, record both objectives. A configuration that
improves mean performance but produces implausible extreme predictions
may be rejected by an explicit scientific decision rule rather than
hidden by a leaderboard.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 10. Small agronomic experiments

Large tuning budgets can overfit tiny development samples. Use a
constrained search space motivated by model behavior, repeated
design-aware resampling, and simple baselines. Search sophistication
cannot create information that the experiment did not collect.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 11. Quantile-oriented irrigation decision support

Point error and interval quality answer different questions. If an
operational decision requires upper-tail protection, optimize a proper
probabilistic score or interval criterion rather than only RMSE.
Multi-objective tuning can retain point and uncertainty performance
together.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

### Practice case 12. Cross-language reproducibility

Do not expect R and Python to generate identical random candidate
sequences from the same integer seed. Freeze candidate configurations
and split manifests when exact cross-language comparison is required,
then compare metric calculations within declared numerical tolerances.

**Questions for review.** What is the experimental or observational
unit? Which domain should remain external? Which operations learn from
outcomes or feature distributions? Which metric represents the
scientific loss? Would a second objective change the preferred
configuration? What evidence would justify increasing the search budget?

## 24. Final perspective

Hyperparameter optimization is scientifically useful when it is
subordinate to the data-generating design and information boundary. The
optimizer should never determine which observations count as
independent, which future population the assessment set represents, or
what scientific utility means. Those choices come first.

The recommended 0.4.0 sequence is:

**declare design -\> protect final evidence -\> construct inner
resampling -\> fit transformations inside folds -\> search
configurations -\> inspect archive -\> retain Pareto set when objectives
conflict -\> apply an explicit compromise rule if necessary -\> estimate
the complete selection procedure with outer validation -\> report
compute, uncertainty, hashes, and limitations.**

The selected hyperparameters are therefore not the endpoint. They are
one reproducible decision inside a larger scientific model-development
procedure.

## Appendix A. Advanced tuning review exercises

### A.1. Search-space scope

A search space should be justified from model behavior, prior empirical
evidence, or backend constraints. Ask whether each bound excludes
scientifically plausible settings and whether widening the domain would
change compute allocation enough to require a new development protocol.
Record changes as a new search-space version rather than silently
extending a completed search. For a review exercise, identify the
corresponding object in the tuning archive, state what evidence would
change your interpretation, and document whether the issue affects model
selection, performance estimation, or only operational deployment.

### A.2. Conditional parameters

Conditional domains reduce meaningless evaluations. Inspect whether
inactive parameters are truly irrelevant to the fitted mechanism,
whether the activation rule is deterministic, and whether the archive
makes inactive values explicit. Conditionality should simplify
interpretation, not conceal different model families under one ambiguous
configuration label. For a review exercise, identify the corresponding
object in the tuning archive, state what evidence would change your
interpretation, and document whether the issue affects model selection,
performance estimation, or only operational deployment.

### A.3. Metric alignment

Selection metrics should correspond to the scientific loss. Compare what
happens when RMSE, MAE, log loss, Brier score, recall, or calibration
error is emphasized. If the preferred configuration changes materially,
the model-development result is metric-sensitive and should be reported
that way. For a review exercise, identify the corresponding object in
the tuning archive, state what evidence would change your
interpretation, and document whether the issue affects model selection,
performance estimation, or only operational deployment.

### A.4. Fold dependence

Resampling folds are not independent experiments. Repeated estimates
share observations and training sets. Use fold variability as
descriptive evidence about stability, not as if it were an ordinary
independent sample of experiments. When formal uncertainty is needed,
use methods whose assumptions match the resampling design. For a review
exercise, identify the corresponding object in the tuning archive, state
what evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.5. Racing elimination

Inspect when each configuration was eliminated and which common folds
supported the decision. Early elimination is efficient only when the
evidence is informative. Very noisy scientific datasets may require more
minimum folds or a more conservative elimination threshold. For a review
exercise, identify the corresponding object in the tuning archive, state
what evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.6. Bayesian optimization surrogate

The surrogate is a model of the tuning objective, not the scientific
response. Poor surrogate fit can misallocate evaluations. Inspect
whether the archive adequately covers the domain, whether expected
improvement repeatedly proposes boundary points, and whether a larger
initial design changes the search trajectory. For a review exercise,
identify the corresponding object in the tuning archive, state what
evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.7. Resource schedules

Successive halving assumes a meaningful resource axis. Verify that
increasing trees, rounds, or epochs represents additional training
rather than a qualitatively different model. Resource schedules should
be reported because they determine which configurations receive enough
compute to demonstrate their potential. For a review exercise, identify
the corresponding object in the tuning archive, state what evidence
would change your interpretation, and document whether the issue affects
model selection, performance estimation, or only operational deployment.

### A.8. Failure handling

Failed fits are information. Record the configuration, backend message,
fold, and resource level. Do not silently drop failures and then
calculate performance only from successful candidates if failure
probability itself matters for operational reliability. For a review
exercise, identify the corresponding object in the tuning archive, state
what evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.9. Seed sensitivity

A single seed freezes one development realization. Repeat scientifically
important searches under a small prespecified seed set when
stochasticity is consequential. Distinguish variation caused by
candidate sampling from variation caused by the learner and from
variation caused by resampling geometry. For a review exercise, identify
the corresponding object in the tuning archive, state what evidence
would change your interpretation, and document whether the issue affects
model selection, performance estimation, or only operational deployment.

### A.10. Nested selection

For each outer fold, inspect the selected configuration and inner score.
Different outer folds can select different settings because the training
data differ. The outer estimate concerns the full selection algorithm,
so there is no requirement that one hyperparameter vector be selected in
every fold. For a review exercise, identify the corresponding object in
the tuning archive, state what evidence would change your
interpretation, and document whether the issue affects model selection,
performance estimation, or only operational deployment.

### A.11. Pareto interpretation

Plot or tabulate nondominated configurations and identify the scientific
meaning of each tradeoff. A crowded Pareto frontier may indicate many
practically equivalent alternatives. A sparse frontier may reveal a
sharper tradeoff between objectives. For a review exercise, identify the
corresponding object in the tuning archive, state what evidence would
change your interpretation, and document whether the issue affects model
selection, performance estimation, or only operational deployment.

### A.12. Compromise rules

A weighted sum transforms objectives according to declared preferences
and normalization. Test whether modest changes in weights alter the
selected configuration. If so, the operational choice is
preference-sensitive and should not be described as an unambiguous
statistical winner. For a review exercise, identify the corresponding
object in the tuning archive, state what evidence would change your
interpretation, and document whether the issue affects model selection,
performance estimation, or only operational deployment.

### A.13. Baseline retention

Keep an untuned or lightly tuned baseline in the development record. If
an expensive optimizer yields only trivial improvement, the simpler
procedure may be scientifically preferable because it is easier to
validate, explain, reproduce, and maintain. For a review exercise,
identify the corresponding object in the tuning archive, state what
evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.14. Search budget fairness

When comparing model families, equal numbers of trials do not always
imply equal compute, and equal compute does not imply equal opportunity
because spaces differ in dimension. Report both trial counts and elapsed
resources so readers can understand the comparison. For a review
exercise, identify the corresponding object in the tuning archive, state
what evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.15. Calibration interaction

Hyperparameters can change probability sharpness and calibration. When
probability quality matters, tune with proper scores or preserve
calibration as a separate objective. Do not optimize hard classification
accuracy and assume the resulting probabilities are automatically
reliable. For a review exercise, identify the corresponding object in
the tuning archive, state what evidence would change your
interpretation, and document whether the issue affects model selection,
performance estimation, or only operational deployment.

### A.16. Imbalance interaction

Sampling and class weighting alter the training distribution and can
interact with tuned parameters. Apply them inside every analysis fold.
Evaluate on unaltered assessment prevalence and avoid letting synthetic
examples enter calibration or final-test datasets. For a review
exercise, identify the corresponding object in the tuning archive, state
what evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.17. Spatial tuning

Spatial hyperparameters can appear excellent under random CV because
nearby samples share information. Repeat selection using the
deployment-relevant spatial geometry. Search sophistication does not
compensate for a geometry that answers the wrong question. For a review
exercise, identify the corresponding object in the tuning archive, state
what evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.18. Temporal tuning

Time-dependent data require availability-aware inner folds.
Hyperparameters selected with future observations in training can
exploit structural changes that would not be known at deployment.
Preserve temporal ordering at every layer of nested validation. For a
review exercise, identify the corresponding object in the tuning
archive, state what evidence would change your interpretation, and
document whether the issue affects model selection, performance
estimation, or only operational deployment.

### A.19. Archive preservation

Save the complete archive, not only the best row. The archive enables
later audit of search behavior, metric sensitivity, compute, failures,
and boundary effects. It also supports independent recalculation of
decision rules without rerunning expensive models. For a review
exercise, identify the corresponding object in the tuning archive, state
what evidence would change your interpretation, and document whether the
issue affects model selection, performance estimation, or only
operational deployment.

### A.20. Scientific stopping

A search can stop because its declared budget is exhausted, because
resource allocation terminates, or because practical gains are
negligible. These stopping rules have different interpretations. Report
which rule operated rather than implying that the global optimum was
proven. For a review exercise, identify the corresponding object in the
tuning archive, state what evidence would change your interpretation,
and document whether the issue affects model selection, performance
estimation, or only operational deployment.

## Appendix B. Interpreting a tuning study as evidence

A tuning study should be read as an experiment conducted on development
data. The factors are hyperparameter configurations, the repeated
observational structure is the resampling design, and the response is
one or more performance measures. This analogy is useful because it
discourages treating every small numerical difference as a stable
scientific finding. The archive documents what was tried, the resampling
design documents where the evidence came from, and the outer validation
layer determines how far the development conclusion can be generalized.

When several configurations differ by less than the natural variability
across defensible folds, the scientifically important conclusion may be
that a broad region of the search space performs similarly. In that
situation, operational simplicity, computation, calibration,
interpretability, or stability can reasonably determine the final
choice. The package should preserve the evidence supporting that
decision rather than forcing a false sense of precision around one
hyperparameter vector.

Tuning also creates multiplicity through repeated adaptation to the same
development sample. Nested resampling addresses optimism in performance
estimation, but it does not make every search decision universally
transferable. A configuration selected on one crop, sensor, region, or
season remains conditional on that development domain. External
validation is still necessary when the claim extends beyond it.

Finally, optimization results should be compared against the scientific
baseline. A sophisticated search that reduces error only trivially may
not justify greater implementation burden, sensitivity to software
versions, or computational cost. The purpose of tuning is to support a
better scientific procedure, not to maximize the number of evaluated
configurations.

### Appendix C. Minimum evidence before changing a search space

A search space should not be widened simply because the current best
configuration lies on a boundary. First inspect whether the apparent
boundary optimum is stable across folds, whether neighboring
configurations show a meaningful performance gradient, whether the
backend interprets the parameter monotonically, and whether the expanded
region remains scientifically and computationally plausible. If the
search space is changed after inspecting results, treat that change as a
new development decision and record a new specification hash. When
confirmatory performance is required, the revised search should be
evaluated with evidence that was not used to motivate the change. This
discipline prevents iterative tuning from silently consuming every
available validation layer.

A conservative release therefore preserves the original boundary and
documents any proposed expansion as a future, separately validated
experiment.

### 1.0.0 consolidation note

In the 1.0.0 Consolidated Scientific Release, this workflow keeps the
same scientific semantics established during development. The public
function contract is frozen from 0.9.0; final certification changes
evidence and backend status, not the design, leakage, uncertainty, or
provenance rules taught in this vignette.
