# Bootstrap and Stability: Match the Resampling Unit to the Scientific Dependence

## Bootstrap and Stability

Bootstrap inference is often described as “resample the data many
times.” That description is incomplete for scientific data. The central
decision is **what constitutes a resampling unit and which dependence
must be preserved**. A case bootstrap assumes exchangeable observational
units. A cluster bootstrap resamples clusters. A hierarchical bootstrap
follows nested sampling levels. Temporal block methods preserve local
serial dependence. Spatial-block bootstrap resamples spatial units
rather than isolated neighboring observations.

`sciModelFlowR` treats bootstrap as an inferential subsystem with
explicit design guards, failure accounting, interval semantics, and
stability diagnostics. A bootstrap distribution is not a Bayesian
posterior, and repeated bootstrap estimates are not independent
experimental replications.

The examples use synthetic Gold datasets. They validate software
behavior and support instruction; they do not provide empirical evidence
about crops, soils, pests, or climate.

### 1. Learning objectives

After completing this vignette, the reader should be able to:

1.  distinguish bootstrap from cross-validation;
2.  identify the correct bootstrap sampling unit from `DesignSpec`;
3.  choose among case, stratified, cluster, hierarchical, moving-block,
    stationary-block, spatial-block, residual, parametric, and wild
    bootstrap concepts;
4.  explain why IID resampling is inappropriate for declared dependence;
5.  compute percentile and basic intervals and understand the conditions
    required by BCa or studentized intervals;
6.  inspect replicate failures rather than silently discarding them;
7.  evaluate stability as the requested number of bootstrap replicates
    increases;
8.  use bootstrap for metrics, statistics, prediction summaries, and
    selection stability without confusing those targets;
9.  report bootstrap settings with enough detail for replication;
10. design simulation studies that evaluate coverage rather than a
    single convenient dataset.

### 2. Main functions

``` r

smf_bootstrap_spec()
smf_validate_bootstrap_design()
smf_bootstrap()
smf_bootstrap_interval()
smf_bootstrap_stability()
```

Version 0.2.0 implements the package-native bootstrap result system and
the principal index-based schemes. Residual, parametric, and wild
pathways use an explicit generator contract so the resampling mechanism
is visible and model-specific generators can be supplied without
changing the result contract. Studentized intervals are available when
`parameters$standard_error` supplies positive finite replicate-specific
standard errors. Unsupported dependence-specific BCa shortcuts remain
blocked rather than silently approximated.

### 3. Bootstrap and cross-validation answer different questions

Cross-validation is primarily used to estimate predictive performance
under a validation geometry. Bootstrap can estimate the sampling
variability of a statistic, the stability of model components, or a
predictive distribution under a defined resampling mechanism.

A five-fold CV distribution of RMSE values is not the same object as a
bootstrap distribution of an RMSE estimate. The folds partition the
observed units and each assessment observation is typically used under a
validation scheme. Bootstrap samples are drawn with replacement and can
contain some original units multiple times while omitting others.

The distinction matters for interpretation. The standard deviation of
bootstrap coefficient estimates describes sensitivity to repeated
samples under the bootstrap design. It does not automatically estimate
external geographic transfer, forecast error, or posterior uncertainty.

### 4. Declare the bootstrap design

A specification records method, requested number of replicates, sampling
unit, block length when relevant, statistic, interval type, confidence
level, seed, and method-specific parameters.

``` r

#| eval: false
bs <- smf_bootstrap_spec(
  method = "case",
  n_resamples = 1999,
  statistic = "mean",
  interval = "percentile",
  level = 0.95,
  seed = 260915L
)
```

The actual statistic passed to
[`smf_bootstrap()`](https://wep69.github.io/sciModelFlowR/reference/additional-api-070.md)
is a function. It should return a finite named numeric vector. Naming
the components is useful because the package can then report intervals
and stability for each component without relying on column positions.

### 5. Case bootstrap

The case bootstrap samples rows with replacement and keeps the same
sample size.

``` r

#| eval: false
d <- smf_load_dataset("gold_linear_regression")

out <- smf_bootstrap(
  d,
  smf_bootstrap_spec("case", n_resamples = 999, seed = 260915L),
  statistic = function(z) c(mean_yield = mean(z$yield))
)

out
smf_bootstrap_interval(out)
```

This workflow is defensible only when rows are the exchangeable sampling
units for the target statistic. If rows are repeated measurements within
a plant or pixels within a leaf, resampling rows breaks the dependence
structure and typically understates uncertainty.

### 6. Stratified bootstrap

A stratified bootstrap resamples within predefined strata so their
composition is retained approximately or exactly, depending on the
implementation.

``` r

#| eval: false
bs <- smf_bootstrap_spec(
  "stratified",
  n_resamples = 999,
  parameters = list(strata = "class")
)

out <- smf_bootstrap(
  classification_data,
  bs,
  statistic = function(z) c(prevalence = mean(z$class == "disease"))
)
```

Strata must be declared before looking at the desired bootstrap result.
Stratification does not repair clustered or temporal dependence. A
stratified row bootstrap remains a row bootstrap.

### 7. Cluster bootstrap

For clustered data, sample clusters with replacement and retain all
observations belonging to each selected cluster.

``` r

#| eval: false
g <- smf_load_dataset("gold_grouped_fields")

design <- smf_design_spec(
  id_column = "obs_id",
  group_columns = "field"
)

bs <- smf_bootstrap_spec(
  "cluster",
  n_resamples = 999,
  sampling_unit = "field",
  seed = 260915L
)

out <- smf_bootstrap(
  g,
  bs,
  statistic = function(z) c(mean_yield = mean(z$yield)),
  design = design
)
```

A selected field can appear more than once in a bootstrap replicate.
That duplication is part of the resampling scheme. The effective
independent sample size is related to the number of fields, not the
number of rows inside fields.

### 8. Hierarchical bootstrap

Scientific data often have nested levels, for example sites containing
fields, fields containing plots, and plots containing repeated
subsamples. A hierarchical bootstrap resamples units at each declared
level rather than flattening the table.

``` r

#| eval: false
bs <- smf_bootstrap_spec(
  "hierarchical",
  n_resamples = 999,
  parameters = list(
    hierarchy = c("site", "field", "plot")
  )
)
```

The order matters. It describes the nesting sequence used by the
resampler. A hierarchy should represent actual sampling or experimental
structure, not a convenient list of categorical columns.

Hierarchical resampling can be especially useful for sensitivity
analyses in ecological, agronomic, physiological, and image-derived
datasets where measurements are nested at several levels. Interpretation
should still identify which population of upper-level units is being
approximated.

### 9. Moving-block bootstrap

Time-series observations are not exchangeable when nearby values are
correlated. The moving-block bootstrap samples contiguous blocks of a
specified length and concatenates them until a replicate reaches the
target size.

``` r

#| eval: false
tm <- smf_load_dataset("gold_time_climate")

design <- smf_design_spec(
  id_column = "obs_id",
  time_column = "time"
)

bs <- smf_bootstrap_spec(
  "moving_block",
  n_resamples = 999,
  block_length = 12,
  parameters = list(order = "time")
)

out <- smf_bootstrap(
  tm,
  bs,
  statistic = function(z) c(mean_response = mean(z$response)),
  design = design
)
```

Block length is a scientific and statistical choice. Very short blocks
approach IID resampling and may destroy dependence. Very long blocks
produce few effectively different blocks and can yield unstable
bootstrap distributions. Report the selected length and, when
conclusions are consequential, examine sensitivity to plausible
alternatives.

### 10. Stationary bootstrap

The stationary bootstrap uses blocks with random lengths, commonly
controlled through a mean block length. Blocks can wrap around the
ordered series, reducing some edge artifacts of fixed blocks.

``` r

#| eval: false
bs <- smf_bootstrap_spec(
  "stationary_block",
  n_resamples = 999,
  block_length = 12,
  parameters = list(order = "time")
)
```

The package records the block-length setting because “stationary
bootstrap” without its dependence parameter is not enough to reconstruct
the analysis.

### 11. Spatial-block bootstrap

Spatially correlated observations can be resampled as predefined or
generated spatial blocks.

``` r

#| eval: false
soil <- smf_load_dataset("gold_spatial_soil")

design <- smf_design_spec(
  id_column = "obs_id",
  coordinate_columns = c("x", "y")
)

bs <- smf_bootstrap_spec(
  "spatial_block",
  n_resamples = 999,
  parameters = list(
    coords = c("x", "y"),
    n_x = 4,
    n_y = 4
  )
)
```

The same caution applied to spatial cross-validation applies here: block
size and coordinate units matter. Resampling tiny blocks from a strongly
autocorrelated surface can still create a bootstrap distribution that is
too narrow for domain-level variability.

### 12. Guard against an IID bootstrap on dependent data

The package uses `DesignSpec` as an active constraint.

``` r

#| eval: false
smf_bootstrap(
  g,
  smf_bootstrap_spec("case", n_resamples = 999),
  statistic = function(z) c(mean_yield = mean(z$yield)),
  design = design
)
```

With a declared grouped design, an ordinary case bootstrap is blocking
by default. The user can explicitly override a guard for methodological
experimentation, but the override remains part of provenance and does
not make the scheme scientifically equivalent to cluster resampling.

### 13. Residual bootstrap

A residual bootstrap is model-based. It typically keeps predictors fixed
and resamples residuals under assumptions about their exchangeability,
then creates new responses from fitted values plus resampled residuals.

This method is not a generic substitute for case resampling. Residual
structure must be compatible with the model, and heteroscedasticity or
dependence can invalidate a simple residual resample.

Residual, parametric, and wild bootstrap use an explicit generator
function supplied in `parameters$generator`. This makes the
model-specific simulation mechanism visible and auditable while keeping
the package-level bootstrap contract backend-independent.

``` r

#| eval: false
bs <- smf_bootstrap_spec(
  "residual",
  n_resamples = 999,
  parameters = list(generator = my_residual_generator)
)
```

A later certified adapter can automate generation for supported fitted
model classes without changing the package-native `BootstrapResult`
contract.

### 14. Parametric bootstrap

A parametric bootstrap draws new responses from a fitted probability
model. Its validity depends directly on that model. For a Gaussian
linear model, this might mean simulating from the fitted mean and
residual scale. For counts, it could mean drawing from a Poisson or
negative-binomial distribution with fitted parameters.

Parametric bootstrap can be powerful for complex statistics, but the
simulation family must be recorded. A result generated under a Gaussian
model should not be described as distribution-free merely because
bootstrap was used.

The development API again requires a transparent generator until
backend-specific simulation pathways are validated.

### 15. Wild bootstrap

The wild bootstrap is designed for settings where residual variability
changes with fitted values or covariates. Instead of resampling
residuals as if they were identically distributed, residual
contributions are multiplied by random weights drawn from a specified
distribution.

The weight distribution is part of the method and should be recorded.
The current generic generator contract allows the analysis to make that
choice explicit rather than embedding an undocumented default.

Wild bootstrap does not fix a wrong mean model or clustered dependence.
It addresses a particular form of heteroscedastic uncertainty under
model assumptions.

### 16. Percentile intervals

The percentile interval takes empirical quantiles of the bootstrap
statistic distribution. It is simple and widely applicable when the
bootstrap distribution adequately approximates the sampling distribution
on the statistic’s scale.

``` r

#| eval: false
bs <- smf_bootstrap_spec(
  "cluster",
  interval = "percentile",
  level = 0.95,
  sampling_unit = "field"
)
```

A percentile interval is not automatically symmetric around the original
estimate. That asymmetry can be informative when the statistic is
skewed.

### 17. Basic intervals

The basic interval reflects bootstrap quantiles around the original
estimate. It uses a different transformation from the percentile
interval and can behave differently under bias or skewness.

The package records the interval method because “95% bootstrap CI” is
incomplete reporting. Readers need to know how the interval was formed
and what unit was resampled.

### 18. BCa intervals require more than a label

Bias-corrected and accelerated intervals use both bias correction and an
acceleration term usually estimated from a jackknife scheme. A
row-delete jackknife is not automatically valid for a cluster,
hierarchical, temporal-block, or spatial-block bootstrap.

For this reason, the 0.2.0 engine blocks generic row-delete BCa for
dependence-aware schemes. A future method can enable cluster- or
block-specific acceleration when the appropriate jackknife is
implemented and validated.

This guard exemplifies a broader package rule: a sophisticated method
name should not be attached to an approximation that does not satisfy
its computational requirements.

### 19. Studentized intervals require replicate standard errors

A studentized bootstrap interval uses a standardized statistic, which
means each bootstrap replicate needs an uncertainty estimate as well as
a point estimate. Computing only bootstrap point estimates and then
labeling a quantile interval “studentized” would be incorrect.

The generic 0.2.0 pathway therefore refuses studentized output until
replicate-specific standard errors are available through a certified
route. This is a capability limitation, not a software failure.

### 20. Replicate failures are part of the evidence

Some resamples can fail because a class disappears, a model becomes
singular, a statistic is undefined, or numerical estimation does not
converge. A package should not silently discard those replicates and
continue as if the requested `B` was achieved.

`BootstrapResult` records:

- requested replicate count;
- successful replicate count;
- failure count;
- failure messages and classes;
- effective bootstrap estimates;
- interval method;
- original statistic;
- stability diagnostics.

A high failure rate may indicate that the statistic is unstable under
plausible samples. That is scientifically relevant.

### 21. How many bootstrap replicates?

There is no single `B` appropriate for every target. Teaching examples
may use small values to demonstrate syntax, but publication-scale
interval estimation generally requires enough replicates for tail
quantiles to stabilize.

Rather than relying only on a conventional number, inspect how estimates
and interval widths change as `B` accumulates.

``` r

#| eval: false
smf_bootstrap_stability(out)
```

The stability table is not a formal convergence proof. It is a practical
diagnostic that can reveal whether conclusions are still moving
materially at the requested replication count.

### 22. Bootstrap targets are not interchangeable

The same resampling engine can support different targets:

- mean or coefficient uncertainty;
- uncertainty in a predictive metric;
- prediction summaries;
- feature-selection frequency;
- calibration statistics;
- model-ranking stability;
- explanation stability.

Each target answers a different question. An interval for a model
coefficient does not quantify the uncertainty of a future individual
response. A distribution of RMSE values does not become a distribution
of model parameters. Reports should name the target explicitly.

### 23. Bootstrap feature-selection stability

Feature selection can change across plausible resamples. Recording only
the variables selected once gives a false sense of determinism.

A stability analysis estimates how often each feature is selected under
a defined resampling scheme. The interpretation depends on the scheme.
Row-level bootstrap frequencies describe sample perturbation under row
exchangeability; cluster bootstrap frequencies describe stability when
clusters are resampled.

For correlated features, individual selection frequencies can be low
even when a group of redundant predictors is consistently informative.
Stability should therefore be interpreted with correlation structure
rather than as an automatic importance ranking.

### 24. A scientifically inappropriate workflow

Suppose 20 measurements are collected from each of 10 experimental
plots. A naive bootstrap samples the 200 rows independently and reports
a very narrow interval for the treatment mean difference. The procedure
behaves as if there were 200 independent experimental units.

The plot-level randomization says otherwise. A cluster bootstrap should
resample the 10 plots, retaining their within-plot measurements. The
resulting interval will usually reflect the much smaller number of
independent units.

The narrow IID interval is not “more precise.” It is precision
calculated under the wrong sampling model.

### 25. Integrated grouped example

``` r

#| eval: false
g <- smf_load_dataset("gold_grouped_fields")

design <- smf_design_spec(
  id_column = "obs_id",
  group_columns = "field"
)

bs <- smf_bootstrap_spec(
  method = "cluster",
  n_resamples = 1999,
  sampling_unit = "field",
  interval = "percentile",
  level = 0.95,
  seed = 260915L
)

result <- smf_bootstrap(
  g,
  bs,
  statistic = function(z) {
    c(
      mean_yield = mean(z$yield),
      sd_yield = sd(z$yield)
    )
  },
  design = design
)

smf_bootstrap_interval(result)
smf_bootstrap_stability(result)
```

The two statistics share bootstrap replicates but have different
sampling distributions. Report each interval with its target and unit.

### 26. Simulation validation of coverage

Software validation should go beyond checking that an interval is
numerically ordered. When the data-generating process is known, repeated
simulation can evaluate whether nominal 95% intervals cover the known
parameter approximately 95% of the time within a predefined tolerance
band.

A valid simulation study freezes:

- data-generating process;
- sample sizes and cluster structure;
- true parameters;
- bootstrap scheme;
- number of bootstrap replicates;
- number of Monte Carlo simulation runs;
- seeds or seed policy;
- acceptance band before results are inspected.

Coverage that is too low indicates anti-conservative uncertainty.
Extremely high coverage accompanied by very wide intervals may indicate
poor efficiency. Both coverage and width matter.

### 27. Reporting checklist

Before reporting bootstrap results, document:

statistic or prediction target;

bootstrap method;

sampling unit;

strata, hierarchy, block geometry, or temporal ordering where
applicable;

requested and successful `B`;

failures and reasons;

interval method and level;

block length or spatial block configuration;

parametric family or residual/wild generator if model-based;

seed strategy;

original estimate;

bootstrap bias when reported;

interval-stability assessment;

sensitivity to plausible dependence choices;

limitations of the bootstrap approximation.

## Applied scientific cases

### Case A. Field trials with subsamples

A field experiment has four soil cores from each plot. Resampling cores
independently treats subsamples as randomized plots. A cluster bootstrap
at plot level better matches the experimental design. If blocks are also
part of randomization, a hierarchical scheme can preserve block and plot
levels. The analysis should state which population of blocks or plots
the bootstrap is intended to represent.

### Case B. Repeated plant physiology

Gas-exchange measurements are recorded repeatedly from the same plants.
A case bootstrap of time-point rows breaks plant-level dependence.
Resampling plants preserves entire trajectories and is defensible for
inference across plants. If the scientific target concerns
temporal-process uncertainty within plants, a more specialized
hierarchical or block strategy may be needed. The unit follows the
estimand.

### Case C. Insect counts through a season

Daily or weekly trap counts are serially dependent. A moving-block or
stationary bootstrap can preserve local temporal structure. Block length
should reflect plausible dependence, and sensitivity to several lengths
is useful. A row bootstrap can create unrealistic series by placing
adjacent biological states in arbitrary order.

### Case D. Spatial soil carbon

Nearby soil samples share spatial structure. Resampling single samples
can underestimate uncertainty for regional summaries. Spatial-block
bootstrap uses larger geographic units, but results depend on block
geometry. Report coordinate units and examine whether conclusions
persist when block size changes.

### Case E. Multi-site agronomic prediction

A model-performance metric is calculated across sites. If the
inferential target is performance in a new site, resample sites rather
than rows. The bootstrap distribution then reflects which sites happen
to be represented. This can be much wider than row-level uncertainty and
more relevant to geographic transfer.

### Case F. Classification calibration

A Brier score or calibration slope can be bootstrapped to describe
sampling variability. If observations are grouped by patient, plant,
field, or acquisition session, the bootstrap must preserve that unit.
Calibration uncertainty from individual rows can be misleading when
predictions within a group are highly correlated.

### Case G. Feature-selection frequency

A spectroscopy workflow selects wavelengths repeatedly. If multiple
scans come from each specimen, specimen-level resampling is preferable
to scan-level bootstrap. A wavelength selected in 90% of scan bootstraps
but only 45% of specimen bootstraps is not equally stable under the
scientifically relevant perturbation.

### Case H. Nonlinear optimum

An agronomic response curve yields an estimated optimum fertilizer dose.
The optimum is a derived statistic and can have a skewed bootstrap
distribution, especially near the experimental boundary. Report the
experimental dose range and avoid presenting a bootstrap interval as
evidence for extrapolated optima outside that range.

### Case I. Rare-event data

Some bootstrap samples may contain too few events for a model to fit.
Those failures should be counted. Silently retaining only successful
replicates can condition the uncertainty analysis on favorable samples.
A high failure rate may indicate that the original dataset contains
insufficient independent information for the requested model.

### Case J. Heavy-tailed response

A mean can be sensitive to a few extreme observations. Bootstrap
analysis may reveal a skewed distribution, but it does not determine
whether the observations are erroneous. Data provenance should be
checked separately. Robust statistics can be bootstrapped as alternative
targets without automatically deleting influential values.

### Case K. Heteroscedastic regression

A residual bootstrap that resamples residuals identically can be
inappropriate when variance changes with fitted level. A wild bootstrap
may better preserve heteroscedastic structure under its assumptions. The
weight distribution and model specification should be recorded. Neither
method repairs a misspecified mean function.

### Case L. Bayesian comparison

A bootstrap distribution of parameter estimates is not a posterior
distribution. Both can quantify uncertainty, but they condition on
different constructions and support different probability statements.
`sciModelFlowR` keeps the uncertainty source typed so reports cannot
silently relabel one as the other.

### Case M. Model-ranking stability

Two algorithms may exchange ranks across bootstrap samples even when
their mean scores differ slightly. Reporting only the mean ranking can
overstate certainty about the winner. A ranking-stability target asks
how often each candidate dominates under plausible resamples and can
reveal practical equivalence.

### Case N. External validation uncertainty

When an external dataset contains several independent sites, resampling
external sites can quantify uncertainty in the external performance
summary. Resampling rows within one external site does not create
evidence about additional sites. The bootstrap unit should match the
domain over which the generalization claim is made.

### Case O. Small cluster count

With only a few independent clusters, cluster-bootstrap distributions
can be unstable and discrete. Increasing `B` does not create more
independent clusters. Report the number of clusters prominently and
consider complementary small-sample methods or a cautious
interpretation. Computational replication cannot compensate for limited
scientific replication.

### Case P. Bootstrap after model tuning

If a tuned workflow is bootstrapped, decide whether each replicate
repeats the tuning process or treats the selected configuration as
fixed. These answer different questions. Repeating tuning estimates
uncertainty of the complete model-selection procedure but is
computationally expensive. Holding tuning fixed conditions on the
selected configuration and can understate selection uncertainty.

### Case Q. Prediction uncertainty

Bootstrapping fitted models can produce a distribution of predicted
values. That distribution usually represents model or sampling
uncertainty, not necessarily the full variability of a future
observation. Observation noise may require an additional simulation
component. Reports should distinguish uncertainty in the expected
response from predictive uncertainty for a new outcome.

### Case R. Stability versus B

An interval may look stable at 500 replicates and move at 2,000 because
tail estimates are noisy. A stability table helps reveal this behavior.
The purpose is not to find a magical convergence threshold but to
document that the requested `B` is adequate for the precision needed in
the scientific conclusion.

## Final perspective

Bootstrap inference is scientifically defensible only when the
resampling mechanism resembles the sampling structure relevant to the
target. The most important bootstrap argument is often not `B`; it is
the sampling unit.

The recommended sequence is:

**target statistic -\> scientific dependence -\> bootstrap unit -\>
replicate generator -\> failure diagnostics -\> interval method -\>
stability versus B -\> simulation coverage when possible -\> explicit
uncertainty interpretation -\> reproducibility record.**

## Part VI. Deeper methodological decisions

### 28. Conditional and unconditional bootstrap targets

A bootstrap analysis can condition on more of the fitted workflow than
the analyst initially realizes. This distinction matters when the
workflow contains preprocessing, feature selection, tuning, calibration,
or a model-selection step.

Consider a prediction pipeline in which variables are standardized, a
subset of predictors is selected, and a regression model is fitted. A
bootstrap that resamples observations but reuses the original
standardization constants and selected variables estimates uncertainty
conditional on those fitted choices. A bootstrap that repeats
standardization and selection inside every replicate estimates
uncertainty of a larger procedure. The second target is usually more
variable because it includes uncertainty from the data-dependent
pipeline.

Neither target is automatically preferable. The report must state what
was repeated. In `sciModelFlowR`, the long-term contract is that every
learned component can declare whether it is refitted inside a replicate.
Version 0.2.0 begins this discipline through explicit resampling units
and fold-safe feature processing.

A useful reporting sentence is:

> Bootstrap replicates repeated the complete training procedure,
> including preprocessing and feature selection, while the final
> external test set remained untouched.

A different valid sentence is:

> Bootstrap intervals condition on the preprocessing and model
> specification selected in the primary analysis and therefore do not
> include model-selection uncertainty.

The distinction is scientific, not merely computational.

### 29. Bias, centering, and what a bootstrap estimate can reveal

For a statistic (), a simple bootstrap estimate of bias is

\[ \_{boot} = -, \]

where (^{\*}) denotes the statistic across bootstrap samples. A nonzero
estimate can be informative, but it should not be interpreted as a
universal correction. Bootstrap bias estimates can themselves be
unstable, especially for small samples, boundary parameters, highly
skewed statistics, or weakly identified models.

The package therefore records the original statistic and replicate
distribution separately. The analyst can inspect whether the bootstrap
distribution is centered close to the original estimate, whether it is
skewed, and whether instability is driven by a subset of replicates. An
automatic bias-corrected estimate should not replace scientific
interpretation of the data-generating process.

For performance metrics, apparent bias can also arise because the
statistic was evaluated on resampled training observations rather than a
held-out assessment set. The resampling geometry used for model
evaluation must remain distinct from the bootstrap used for inferential
uncertainty.

### 30. Choosing block length in temporal bootstrap

Moving-block and stationary bootstrap methods require a block length or
mean block length. This choice controls how much local dependence is
preserved.

Blocks that are too short approach IID resampling and can destroy serial
structure. Blocks that are too long reduce the effective number of
independent pieces and can produce highly variable replicates. There is
no universal block length that is correct for every process.

A practical scientific workflow is:

1.  inspect the time scale of the process and sampling interval;
2.  examine residual autocorrelation after the primary model rather than
    raw autocorrelation alone;
3.  identify plausible dependence horizons;
4.  fit the bootstrap under several scientifically plausible block
    lengths;
5.  compare interval width, bias, failure rate, and substantive
    conclusions;
6.  record the selected length and sensitivity analysis.

For example, weekly pest-trap counts may have a dependence horizon of
several weeks. A block length of two observations and a block length of
twenty observations imply very different assumptions. The selected value
should not be hidden inside software defaults.

### 31. Spatial block size and geometry sensitivity

Spatial bootstrap has an analogous problem. Block size determines which
spatial relationships remain intact within a resampled unit.

A block that is much smaller than the empirical correlation range can
split strongly dependent samples across independent resampling units. A
block that is extremely large may leave only a few effective spatial
replicates. Rectangular blocks are convenient computationally but need
not correspond to ecological or management units.

Before spatial bootstrap, record:

- coordinate reference system;
- coordinate units;
- approximate spatial support of each observation;
- plausible correlation range or management-unit scale;
- block origin and geometry;
- number of occupied blocks;
- sensitivity to alternative origins or sizes.

The current 0.2.0 spatial block implementation treats supplied
coordinates numerically. Geographic longitude and latitude should not be
interpreted as metric distances without an appropriate projection or
distance-aware preprocessing step. The package should warn rather than
silently treating degrees as metres.

### 32. Failure rates are scientific diagnostics

A bootstrap replicate may fail because the fitted model is too complex
for that resample, a class disappears, a factor has only one level, a
variance component reaches a boundary, an optimizer fails, or a
statistic becomes undefined.

The proportion of failures is part of the result. A low failure rate may
be an expected numerical nuisance. A large failure rate can signal that
the requested model is only weakly supported by the independent
information in the data.

Suppose 1,999 replicates are requested and only 1,210 succeed. Reporting
an interval based on the successful replicates without mentioning 789
failures can substantially misrepresent the analysis. The surviving
samples may be systematically easier to fit.

`SMFBootstrapResult` therefore records requested, successful, and failed
replicate counts and retains failure messages. Future releases can
classify failures into statistical and computational categories, but the
0.2.0 contract already treats failure frequency as reportable evidence.

### 33. Bootstrap, conformal prediction, and Bayesian uncertainty answer different questions

These approaches can all produce intervals, but their meanings differ.

A bootstrap confidence interval describes sampling uncertainty under a
specified resampling mechanism. A Bayesian credible interval summarizes
a posterior distribution under a likelihood and prior. A conformal
interval or prediction set targets a coverage guarantee under the
assumptions of the conformal procedure. A model-based prediction
interval combines uncertainty components according to a fitted
probabilistic model.

The visual similarity of two 95% intervals does not make them
interchangeable. `sciModelFlowR` preserves the uncertainty source in
result metadata so that downstream tables and plots can label the
interval correctly.

When several uncertainty approaches are compared, the scientific report
should ask whether their targets are comparable before comparing widths.
A narrow parameter confidence interval and a wide future-observation
prediction interval are not competing estimates of the same quantity.

### 34. Bootstrap after external validation

External validation should remain external. If a final model is
evaluated on an independently collected external domain, the external
labels should not be used to retune the model before the primary
external result is reported.

Bootstrap can nevertheless quantify uncertainty in the external metric.
The resampling unit must reflect the external sampling structure. If the
external study contains ten farms with many observations per farm, a
farm-level bootstrap can represent uncertainty across farms. Row-level
bootstrap primarily represents uncertainty conditional on those farms.

If only one external farm is available, resampling rows from that farm
cannot support a claim about variability across farms. The limitation is
scientific replication, not the number of bootstrap replicates.

### 35. Bootstrap and selection of a single best model

A bootstrap can reveal that apparently decisive model rankings are
unstable. For every replicate, an analyst may calculate the difference
in RMSE between two candidates, the rank of each model, or the frequency
with which a candidate is preferred under a predefined decision rule.

This is more informative than reporting that Model A has RMSE 5.21 and
Model B has RMSE 5.24 and declaring A the winner. If the ranking
reverses in 48% of defensible bootstrap replicates, the observed
difference is not a stable scientific distinction.

Model-ranking stability should not be used to tune on the final test
set. The same separation of inner model selection and outer evaluation
used in nested resampling must remain intact.

### 36. Computational reproducibility of bootstrap experiments

Large bootstrap experiments require reproducible seed management. A
single global call to [`set.seed()`](https://rdrr.io/r/base/Random.html)
is often insufficient documentation when computations are parallelized
or resumed.

A reproducible record should include:

- root seed or seed policy;
- RNG kind;
- mapping from replicate index to generated sample where feasible;
- package and backend versions;
- parallel backend and worker count;
- failed replicate indices;
- statistic definition;
- dataset hash;
- design and bootstrap spec hashes.

Changing the number of workers should not silently change the scientific
meaning of a frozen validation experiment. Publication simulation
batteries should preserve their seed plan and manifests together with
the resulting summary tables.

### 37. A practical decision guide

| Scientific structure | Default bootstrap starting point | Main caution |
|----|----|----|
| Independent observational units | case | confirm independence is scientifically plausible |
| Class or treatment strata | stratified | preserve intended strata without masking dependence |
| Clustered plots or subjects | cluster | resample complete independent clusters |
| Nested block and plot design | hierarchical | encode hierarchy in the correct order |
| Ordered serial process | moving or stationary block | justify block length |
| Spatially dependent observations | spatial block | justify projection, block scale, and geometry |
| Heteroscedastic regression | wild, model-specific | document weight generator and mean model |
| Parametric fitted model | parametric | record simulation model and fitted parameters |
| Prediction metric across sites | cluster/site bootstrap | align unit with transfer claim |
| Feature-selection stability | design-aware bootstrap | refit selector inside every replicate |

This table is a starting point, not an automatic method selector.
Multiple forms of dependence may coexist. A trial with sites, plots
within sites, and repeated measurements over time may require a
hierarchical strategy that preserves more than one structure.

## Additional applied cases

### Case S. Remote-sensing pixels within plots

Thousands of pixels can be extracted from each experimental plot.
Pixel-level bootstrap produces a large nominal sample but does not
create new independently randomized plots. If the scientific claim
concerns new plots or fields, resample at plot or field level. Pixel
subsampling may still be useful as an internal computational
approximation, but it should not be presented as the inferential
replication level.

### Case T. Hyperspectral scans from the same specimen

Repeated scans can capture instrument variability. If the target is
specimen-level prediction, resample specimens and carry all their scans
together. If the target is repeatability of the instrument conditional
on specimens, scan-level perturbation may answer a different question.
The same dataset can support different bootstrap units because the
estimands differ.

### Case U. Climate indices observed monthly

Monthly climate indices often contain seasonality and serial dependence.
Resampling individual months can destroy seasonal structure. A block
bootstrap can preserve short-range dependence, but the analyst should
also consider whether the model has already removed deterministic
seasonality and trend. Resampling raw nonstationary series without
accounting for trend can mix process changes with sampling uncertainty.

### Case V. Multi-environment cultivar ranking

Cultivar rankings can be bootstrapped over environments to evaluate
stability of recommendations across environments. This target differs
from resampling individual plot residuals within the observed
environments. The first asks about environmental transfer; the second is
conditional on the sampled environments. Reporting both can reveal why a
cultivar appears precise within trials but uncertain across regions or
seasons.

### Case W. Threshold optimization in classification

If a classification threshold is estimated from data, a bootstrap that
reuses the original threshold conditions on threshold selection.
Re-estimating the threshold inside each replicate propagates
threshold-selection uncertainty. The final test set must remain isolated
from both procedures.

### Case X. Calibration curves with rare positives

Bootstrap calibration curves may become unstable when some replicates
contain very few positive outcomes. Stratification can preserve class
counts, but grouping and clustering remain relevant. A stratified row
bootstrap is not sufficient when outcomes are clustered by farm,
patient, image acquisition, or subject.

### Case Y. Stability of an agronomic decision rule

Suppose fertilizer recommendation depends on whether predicted yield
gain exceeds a practical threshold. Bootstrap can estimate how often the
recommendation changes across defensible resamples. This decision
stability can be more useful than uncertainty in a single coefficient
because it operates on the scale of the actual agronomic decision.

### Case Z. When bootstrap should not be forced

Bootstrap is not a remedy for every uncertainty problem. Extremely small
numbers of independent units, severe extrapolation, non-identifiability,
a fundamentally misspecified model, or an unsupported sampling mechanism
can make a bootstrap interval misleading. The correct output may be a
warning that the data do not support the requested uncertainty
statement. `sciModelFlowR` treats such warnings as part of the
scientific result rather than as obstacles to be suppressed.

#### Release note on uncertainty layers

Bootstrap uncertainty remains distinct from calibrated class probability
uncertainty. A resampling distribution describes variation under its
sampling scheme; probability calibration instead evaluates
correspondence between predicted probabilities and observed event
frequencies on appropriately held-out data.

### Release 0.4 note: bootstrap versus tuning variability

Bootstrap variation and hyperparameter-selection variation answer
different questions. A bootstrap distribution may describe uncertainty
in a statistic conditional on a specified fitting procedure, whereas
nested tuning evaluates a procedure that can choose different
configurations in different outer folds. Do not merge these sources into
one generic error bar without a method that explicitly combines them.
When both are scientifically relevant, report them separately: tuning or
outer-resampling variability for model-development stability, and
bootstrap uncertainty for the statistic or prediction target defined by
the bootstrap scheme.

When model selection is adaptive, state clearly whether the bootstrap
conditions on the selected configuration or repeats the entire selection
procedure. These are different inferential targets and can produce
different uncertainty estimates.

### 1.0.0 consolidation note

In the 1.0.0 Consolidated Scientific Release, this workflow keeps the
same scientific semantics established during development. The public
function contract is frozen from 0.9.0; final certification changes
evidence and backend status, not the design, leakage, uncertainty, or
provenance rules taught in this vignette.
