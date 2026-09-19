# Data Audit and Leakage: A Design-Aware Workflow

## Data Audit and Leakage: A Design-Aware Workflow

Data auditing in scientific modeling is not generic data cleaning. It
establishes whether the table, variable roles, provenance, and
information timing are compatible with the prediction question before
any estimator is compared.

> This focused vignette uses `gold_binary_calibration`, a frozen
> synthetic Gold dataset. It is instructional and validation material,
> not field evidence.

### 1. Learning objectives

By the end of this vignette, the reader should be able to:

- declare targets and predictors explicitly
- distinguish schema defects, duplicate structures, and missingness from
  scientific dependence
- detect exact target copies and interpret near-exact associations
  cautiously
- explain target, temporal, group, and preprocessing leakage
- preserve warnings as part of the result and manifest
- design a leakage investigation that does not silently delete
  observations

### 2. Why this topic matters scientifically

Data auditing in scientific modeling is not generic data cleaning. It
establishes whether the table, variable roles, provenance, and
information timing are compatible with the prediction question before
any estimator is compared. A scientifically strong workflow makes the
relevant information boundary explicit before model fitting. The package
therefore represents this topic as a contract that can be inspected,
serialized, tested, and carried into later modules.

The main risk is not simply a software exception. A workflow can execute
successfully and still answer a different scientific question from the
one stated by the researcher. This vignette emphasizes how to detect
that mismatch, how to document it, and how to avoid turning a convenient
default into an unjustified assumption.

### 3. Functions used

``` r

d <- smf_load_dataset("gold_binary_calibration")
spec <- smf_data_spec("event", c("x1", "x2"), id_column = "obs_id")
smf_audit_data(d, spec)
```

### 4. Scientific target

Begin by stating what future observation, group, time, or domain the
analysis is intended to generalize to. A validation design is meaningful
only relative to that target.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

``` r

#| eval: false
d <- smf_load_dataset("gold_binary_calibration")
spec <- smf_data_spec("event", c("x1", "x2"), id_column = "obs_id")
smf_audit_data(d, spec)
```

### 5. Unit of analysis

Rows are storage units, not automatically independent scientific units.
Record the unit that was sampled, randomized, repeatedly measured, or
spatially located.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

``` r

#| eval: false
bad <- d
bad$event_copy <- bad$event
smf_detect_leakage(bad, smf_data_spec("event", c("x1","x2","event_copy"), "obs_id"))
```

### 6. Specification before computation

Use package-native specs to make assumptions inspectable before a model
is fitted. This avoids reconstructing scientific intent from backend
formulas after the fact.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

``` r

#| eval: false
smf_missingness_report(d)
```

### 7. Evidence and severity

Separate a detected violation from a heuristic warning. Strong evidence
can block a managed workflow, whereas an ambiguous signal should trigger
provenance review rather than automatic deletion.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

``` r

#| eval: false
audit <- smf_audit_data(d, spec)
audit@quality_flags
```

### 8. Portable metadata

Stable IDs, hashes, and serialized specs allow another implementation or
another analyst to reproduce membership and meaning without copying R
internal objects.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

``` r

#| eval: false
smf_to_json(spec)
smf_hash(spec)
```

### 9. Training boundary

Any statistic learned from data belongs to a fitting boundary.
Imputation, centering, encoding, feature selection, calibration, and
tuning must not learn from final test labels.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 10. Diagnostics before interpretation

A successful optimizer or model fit is only the start. Diagnostics ask
whether the fitted object behaves consistently with the scientific
assumptions and intended output.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 11. Observed data and estimates

When feasible, show observations with fitted or predicted quantities.
This makes scale, support, unusual cases, and uncertainty visible
instead of hiding them behind one summary metric.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 12. Uncertainty language

Name the source and target of uncertainty. Sampling variation,
resampling variation, posterior uncertainty, predictive uncertainty, and
conformal coverage have different interpretations.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 13. Reproducibility manifest

Record versions, hashes, seeds, split membership, preprocessing
identity, warnings, and outputs. Reproducibility metadata should be
generated by the workflow, not reconstructed later.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 14. Failure mode

A tempting shortcut can create optimistic evidence while leaving no
software error. Teaching an incorrect path is useful when the package
can explain why it is inappropriate.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 15. External validity

Performance is conditional on the held-out domain. Avoid language about
universal generalization when the validation data do not represent the
intended population, season, region, instrument, or management context.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 16. Cross-language parity

R and Python should agree on scientific semantics and frozen membership,
not internal syntax. Shared CSV/JSON fixtures make meaningful
differential tests possible.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 17. Testing strategy

Combine unit, integration, numerical, golden, invariant, and simulation
tests. Each catches a different class of defect; no one style
substitutes for all others.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 18. Reporting discipline

Report the design, validation geometry, preprocessing boundary, metrics,
warnings, and limitations along with the fitted model. A model table
alone is incomplete.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 19. Escalating complexity

Add a more complex method only when it solves a stated problem. The
package roadmap is staged so new engines do not redefine earlier
scientific contracts.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 20. Review questions

A reviewer should be able to ask which rows informed each learned step,
which units crossed partitions, what the test set represents, and how
warnings were handled.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 21. Connection to later versions

The 0.1.0 contract becomes input to full resampling, bootstrap, tuning,
probabilistic, Bayesian, and Deep-Learning modules. Preserving meaning
now reduces migration later.

For `gold_binary_calibration`, this principle can be inspected directly
because the generator and expected structure are documented. The
exercise should begin with the scientific declaration, then use the
package guard or result object to inspect evidence. The goal is not to
make the software choose the scientific question automatically. The goal
is to prevent that question from disappearing between data preparation
and model reporting.

When adapting the example to empirical data, document what differs from
the Gold scenario: sampling frame, unit, dependence, missingness,
measurement process, target domain, and any transformations performed
outside the package. Those differences can change the correct validation
strategy even when the R function call looks similar.

### 22. Scientifically inappropriate workflow

A common but invalid workflow is to create a predictor from the final
response or a post-outcome measurement, use it during model fitting, and
then interpret the excellent test score as evidence of scientific
predictability. Another form is to estimate preprocessing or
feature-selection parameters from the entire dataset before splitting.
Both workflows allow held-out information to influence training.

The package should make this problem visible through a structured
warning or blocking condition whenever enough evidence is available. If
the situation is ambiguous, the correct response is to document the
uncertainty and inspect provenance, not to silently repair the data.

### 23. Interpretation guide

Interpretation should move from design validity to data quality, then
validation geometry, then fitted behavior, then performance, then
uncertainty and limitations. This order reduces the chance that a
favorable metric dominates decisions that should have been made earlier.

A scientifically appropriate conclusion is conditional: it states what
was predicted, for which held-out units or domain, under which
preprocessing and model, with which uncertainty and diagnostic evidence.
It should not claim causal effects from a predictive workflow or
geographic/temporal transfer beyond the validation evidence.

### 24. Reporting checklist

target and predictor roles recorded;

ID and provenance columns separated from predictors;

missingness summarized without silent deletion;

duplicate rows and duplicate IDs interpreted using study design;

target-derived and post-outcome variables investigated;

preprocessing fitted only within training;

leakage warnings retained in the result;

any override documented with scientific justification;

final claim matches the information available at prediction time.

### 25. Connection to the complete workflow

- Continue to the design vignette to connect audit findings with
  experimental units and validation geometry.
- Revisit this vignette before adding supervised feature selection,
  calibration, or tuning, because each can create a new leakage pathway.

The next vignette should be read as an extension of this contract rather
than as an unrelated collection of functions. The stable scientific
grammar is what allows the package to expand while keeping results
comparable and auditable.

### Appendix. Applied review cases

#### Case 1

A researcher changes only the random seed and obtains another split. The
package should make the changed split hash visible so the new estimate
is not confused with the previous result.

A useful review response should identify the affected contract, the
evidence available, whether the issue changes the estimand or validation
target, and what must be rerun. The response should not be reduced to
whether the software produced an error.

#### Case 2

A collaborator sends a CSV with identical values but rows in a different
order. An ID-based external manifest can recover the intended membership
without depending on row positions.

A useful review response should identify the affected contract, the
evidence available, whether the issue changes the estimand or validation
target, and what must be rerun. The response should not be reduced to
whether the software produced an error.

#### Case 3

A high-performing predictor is later discovered to be recorded after the
outcome. The correct action is to revise the predictor set and the
scientific claim, not merely note the issue in discussion.

A useful review response should identify the affected contract, the
evidence available, whether the issue changes the estimand or validation
target, and what must be rerun. The response should not be reduced to
whether the software produced an error.

#### Case 4

A model has slightly worse RMSE but cleaner external-domain behavior.
The workflow should preserve both pieces of evidence rather than forcing
a single automatic winner.

A useful review response should identify the affected contract, the
evidence available, whether the issue changes the estimand or validation
target, and what must be rerun. The response should not be reduced to
whether the software produced an error.

#### Case 5

A manuscript reports a 95% interval without identifying its type. The
result contract should provide enough metadata to label the interval
correctly in tables and figures.

A useful review response should identify the affected contract, the
evidence available, whether the issue changes the estimand or validation
target, and what must be rerun. The response should not be reduced to
whether the software produced an error.

#### Case 6

A reviewer asks whether preprocessing used held-out rows. The stored
training hash and preprocessing provenance should answer the question
directly.

A useful review response should identify the affected contract, the
evidence available, whether the issue changes the estimand or validation
target, and what must be rerun. The response should not be reduced to
whether the software produced an error.

#### Case 7

Two language implementations use different RNG algorithms. They can
still be tested on the same frozen split IDs and expected numerical
quantities.

A useful review response should identify the affected contract, the
evidence available, whether the issue changes the estimand or validation
target, and what must be rerun. The response should not be reduced to
whether the software produced an error.

#### Case 8

An optional backend is missing on one computer. Core auditing, design
inspection, Gold data, and manifests should remain available rather than
making the whole package unloadable.

A useful review response should identify the affected contract, the
evidence available, whether the issue changes the estimand or validation
target, and what must be rerun. The response should not be reduced to
whether the software produced an error.

### Extended methodological notes

#### Note 1

When a workflow is adapted to a new study, begin by rewriting the
scientific question in terms of a target population and prediction time.
This often reveals that a convenient random split is answering the wrong
question. The package can encode constraints, but the user remains
responsible for defining the intended domain.

#### Note 2

Keep provenance columns even when they are excluded from model
predictors. Site, season, instrument, plant, plot, subject, acquisition
date, and processing batch can be essential for auditing dependence or
shift. Removing them early may make leakage impossible to diagnose
later.

#### Note 3

Prefer explicit failure over a scientifically different fallback. If a
requested method is unsupported, the workflow should name the missing
capability and propose alternatives while preserving the scientific
target. Silent substitution makes results difficult to compare and can
change uncertainty semantics.

#### Note 4

Separate descriptive summaries from inferential or predictive evidence.
Descriptive means and missingness tables are useful for understanding
support, but they do not account for design, validation, model
uncertainty, or multiplicity. Documentation should label these roles
clearly.

#### Note 5

Use stable objects and manifests to make revisions auditable. When a
manuscript revision changes predictors, grouping, preprocessing, or test
membership, the corresponding hash should change. This makes it easier
to identify why a result differs from an earlier draft.

#### Note 6

Do not treat simulation as empirical validation of a substantive
agricultural claim. Simulation can validate the statistical behavior of
software under a known data-generating process. Evidence about real
crops, soils, climates, sensors, or populations requires appropriately
collected empirical data.

#### Note 7

A warning should carry evidence and an action. Messages that merely say
something is suspicious are difficult to review. Structured warnings
allow reports to distinguish what was detected, why severity was
assigned, and whether the user overrode the safeguard.

#### Note 8

Testing should focus on meaning. A numerical adapter test should compare
predictions or estimands with a trusted reference. A serialization test
should compare reconstructed semantics. Exact formatting is only
important when formatting itself is part of a stable public contract.

#### Note 9

When a workflow is adapted to a new study, begin by rewriting the
scientific question in terms of a target population and prediction time.
This often reveals that a convenient random split is answering the wrong
question. The package can encode constraints, but the user remains
responsible for defining the intended domain.

#### Note 10

Keep provenance columns even when they are excluded from model
predictors. Site, season, instrument, plant, plot, subject, acquisition
date, and processing batch can be essential for auditing dependence or
shift. Removing them early may make leakage impossible to diagnose
later.

#### Note 11

Prefer explicit failure over a scientifically different fallback. If a
requested method is unsupported, the workflow should name the missing
capability and propose alternatives while preserving the scientific
target. Silent substitution makes results difficult to compare and can
change uncertainty semantics.

#### Note 12

Separate descriptive summaries from inferential or predictive evidence.
Descriptive means and missingness tables are useful for understanding
support, but they do not account for design, validation, model
uncertainty, or multiplicity. Documentation should label these roles
clearly.

#### Note 13

Use stable objects and manifests to make revisions auditable. When a
manuscript revision changes predictors, grouping, preprocessing, or test
membership, the corresponding hash should change. This makes it easier
to identify why a result differs from an earlier draft.

#### Note 14

Do not treat simulation as empirical validation of a substantive
agricultural claim. Simulation can validate the statistical behavior of
software under a known data-generating process. Evidence about real
crops, soils, climates, sensors, or populations requires appropriately
collected empirical data.

#### Note 15

A warning should carry evidence and an action. Messages that merely say
something is suspicious are difficult to review. Structured warnings
allow reports to distinguish what was detected, why severity was
assigned, and whether the user overrode the safeguard.

#### Note 16

Testing should focus on meaning. A numerical adapter test should compare
predictions or estimands with a trusted reference. A serialization test
should compare reconstructed semantics. Exact formatting is only
important when formatting itself is part of a stable public contract.

#### Note 17

When a workflow is adapted to a new study, begin by rewriting the
scientific question in terms of a target population and prediction time.
This often reveals that a convenient random split is answering the wrong
question. The package can encode constraints, but the user remains
responsible for defining the intended domain.

#### Note 18

Keep provenance columns even when they are excluded from model
predictors. Site, season, instrument, plant, plot, subject, acquisition
date, and processing batch can be essential for auditing dependence or
shift. Removing them early may make leakage impossible to diagnose
later.

#### Note 19

Prefer explicit failure over a scientifically different fallback. If a
requested method is unsupported, the workflow should name the missing
capability and propose alternatives while preserving the scientific
target. Silent substitution makes results difficult to compare and can
change uncertainty semantics.

#### Note 20

Separate descriptive summaries from inferential or predictive evidence.
Descriptive means and missingness tables are useful for understanding
support, but they do not account for design, validation, model
uncertainty, or multiplicity. Documentation should label these roles
clearly.

#### Note 21

Use stable objects and manifests to make revisions auditable. When a
manuscript revision changes predictors, grouping, preprocessing, or test
membership, the corresponding hash should change. This makes it easier
to identify why a result differs from an earlier draft.

#### Note 22

Do not treat simulation as empirical validation of a substantive
agricultural claim. Simulation can validate the statistical behavior of
software under a known data-generating process. Evidence about real
crops, soils, climates, sensors, or populations requires appropriately
collected empirical data.

#### Note 23

A warning should carry evidence and an action. Messages that merely say
something is suspicious are difficult to review. Structured warnings
allow reports to distinguish what was detected, why severity was
assigned, and whether the user overrode the safeguard.

#### Note 24

Testing should focus on meaning. A numerical adapter test should compare
predictions or estimands with a trusted reference. A serialization test
should compare reconstructed semantics. Exact formatting is only
important when formatting itself is part of a stable public contract.

#### Note 25

When a workflow is adapted to a new study, begin by rewriting the
scientific question in terms of a target population and prediction time.
This often reveals that a convenient random split is answering the wrong
question. The package can encode constraints, but the user remains
responsible for defining the intended domain.

#### Note 26

Keep provenance columns even when they are excluded from model
predictors. Site, season, instrument, plant, plot, subject, acquisition
date, and processing batch can be essential for auditing dependence or
shift. Removing them early may make leakage impossible to diagnose
later.

#### Note 27

Prefer explicit failure over a scientifically different fallback. If a
requested method is unsupported, the workflow should name the missing
capability and propose alternatives while preserving the scientific
target. Silent substitution makes results difficult to compare and can
change uncertainty semantics.

#### Note 28

Separate descriptive summaries from inferential or predictive evidence.
Descriptive means and missingness tables are useful for understanding
support, but they do not account for design, validation, model
uncertainty, or multiplicity. Documentation should label these roles
clearly.

#### Note 29

Use stable objects and manifests to make revisions auditable. When a
manuscript revision changes predictors, grouping, preprocessing, or test
membership, the corresponding hash should change. This makes it easier
to identify why a result differs from an earlier draft.

#### Note 30

Do not treat simulation as empirical validation of a substantive
agricultural claim. Simulation can validate the statistical behavior of
software under a known data-generating process. Evidence about real
crops, soils, climates, sensors, or populations requires appropriately
collected empirical data.

#### Note 31

A warning should carry evidence and an action. Messages that merely say
something is suspicious are difficult to review. Structured warnings
allow reports to distinguish what was detected, why severity was
assigned, and whether the user overrode the safeguard.

#### Note 32

Testing should focus on meaning. A numerical adapter test should compare
predictions or estimands with a trusted reference. A serialization test
should compare reconstructed semantics. Exact formatting is only
important when formatting itself is part of a stable public contract.

#### Note 33

When a workflow is adapted to a new study, begin by rewriting the
scientific question in terms of a target population and prediction time.
This often reveals that a convenient random split is answering the wrong
question. The package can encode constraints, but the user remains
responsible for defining the intended domain.

#### Note 34

Keep provenance columns even when they are excluded from model
predictors. Site, season, instrument, plant, plot, subject, acquisition
date, and processing batch can be essential for auditing dependence or
shift. Removing them early may make leakage impossible to diagnose
later.

#### Note 35

Prefer explicit failure over a scientifically different fallback. If a
requested method is unsupported, the workflow should name the missing
capability and propose alternatives while preserving the scientific
target. Silent substitution makes results difficult to compare and can
change uncertainty semantics.

#### Note 36

Separate descriptive summaries from inferential or predictive evidence.
Descriptive means and missingness tables are useful for understanding
support, but they do not account for design, validation, model
uncertainty, or multiplicity. Documentation should label these roles
clearly.

#### Note 37

Use stable objects and manifests to make revisions auditable. When a
manuscript revision changes predictors, grouping, preprocessing, or test
membership, the corresponding hash should change. This makes it easier
to identify why a result differs from an earlier draft.

#### Note 38

Do not treat simulation as empirical validation of a substantive
agricultural claim. Simulation can validate the statistical behavior of
software under a known data-generating process. Evidence about real
crops, soils, climates, sensors, or populations requires appropriately
collected empirical data.

#### Note 39

A warning should carry evidence and an action. Messages that merely say
something is suspicious are difficult to review. Structured warnings
allow reports to distinguish what was detected, why severity was
assigned, and whether the user overrode the safeguard.

#### Note 40

Testing should focus on meaning. A numerical adapter test should compare
predictions or estimands with a trusted reference. A serialization test
should compare reconstructed semantics. Exact formatting is only
important when formatting itself is part of a stable public contract.

#### Final teaching note

A focused vignette is intentionally shorter than the integrating
tutorial, but it should still present a complete scientific workflow.
The reader should be able to identify the question, declare the relevant
design, inspect a tempting incorrect path, run the package safeguard,
interpret the evidence, and finish with a reproducibility and reporting
checklist. The aim is not to repeat the central tutorial verbatim. It is
to deepen one decision while preserving the same analysis grammar,
terminology, warning semantics, Gold-data policy, and distinction
between descriptive summaries and inferential or predictive evidence.

### Release-note extension for 0.2.0

Version 0.2.0 connects audit evidence directly to the expanded
validation geometry. Group, temporal, spatial, and external-domain
declarations are no longer only metadata for later use. They now
constrain the resampling methods that can be created without an explicit
override. This makes an early audit finding operational: the package can
prevent a convenient random split from contradicting the scientific
structure declared by the analyst. The same principle applies to feature
learning and bootstrap units.

#### Release note on audit boundaries

In 0.3.0, probability calibration and imbalance handling inherit the
same audit principle: labels reserved for final evaluation must not
influence learned preprocessing, sampling, calibration, threshold
selection, or model choice.

### Release 0.4 note: audit before adaptive model development

Version 0.4.0 makes the earlier audit boundary even more important
because tuning repeatedly adapts model settings to development evidence.
A variable that leaks outcome information can therefore influence not
only one fitted model but the entire search trajectory and selected
configuration. Before launching a search, re-run the audit on the exact
development data, verify identifiers and time ordering, and confirm that
any external domain remains excluded. If a new predictor, imputation
rule, or derived feature is introduced during tuning, treat that change
as a new development specification and update the provenance record.

A final audit should therefore be treated as a gate before any adaptive
search. If its result changes after feature engineering or data
cleaning, freeze a new audit artifact and explain the change.

### 1.0.0 consolidation note

In the 1.0.0 Consolidated Scientific Release, this workflow keeps the
same scientific semantics established during development. The public
function contract is frozen from 0.9.0; final certification changes
evidence and backend status, not the design, leakage, uncertainty, or
provenance rules taught in this vignette.
