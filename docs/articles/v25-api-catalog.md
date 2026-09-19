# Stable 1.x API Catalog

## Stable 1.x API Catalog

**Package:** `sciModelFlowR`\
**Release:** 1.0.0\
**Role:** focused stable-release vignette

This tutorial develops a package API governance workflow while
preserving the package rule that design and provenance precede algorithm
choice. Every dataset used here is a frozen synthetic Gold fixture for
software validation and instruction, not empirical evidence.

The canonical sequence is **catalog -\> capabilities -\> stable result
contract -\> backend status -\> release evidence**. The principal entry
points are
[`smf_api_catalog()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md),
[`smf_backend_matrix()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md),
[`smf_capabilities()`](https://wep69.github.io/sciModelFlowR/reference/smf_core_api.md),
[`smf_release_candidate_audit()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md),
[`smf_run_reference_validation()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md),
[`smf_run_crosslang_validation()`](https://wep69.github.io/sciModelFlowR/reference/release-candidate-090.md).

### 2. Scientific question and estimand

In package API governance, the scientific question and estimand stage
should preserve the unit that was sampled, randomized, measured, or
externally validated. A central failure mode is **choosing a function
without checking its contract**. The consolidated 1.0.0 workflow records
the admissible training domain, transformation state, assessment
boundary, warnings, hashes, and backend identity. A numerically
attractive result does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 3. Design declaration

In package API governance, the design declaration stage should preserve
the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **assuming source adapter equals
certified backend**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 4. Data audit and leakage

In package API governance, the data audit and leakage stage should
preserve the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **bypassing package-native
results**. The consolidated 1.0.0 workflow records the admissible
training domain, transformation state, assessment boundary, warnings,
hashes, and backend identity. A numerically attractive result does not
repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 5. Protected splitting and resampling

In package API governance, the protected splitting and resampling stage
should preserve the unit that was sampled, randomized, measured, or
externally validated. A central failure mode is **choosing a function
without checking its contract**. The consolidated 1.0.0 workflow records
the admissible training domain, transformation state, assessment
boundary, warnings, hashes, and backend identity. A numerically
attractive result does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 6. Training-only preprocessing

In package API governance, the training-only preprocessing stage should
preserve the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **assuming source adapter equals
certified backend**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 7. Feature learning

In package API governance, the feature learning stage should preserve
the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **bypassing package-native
results**. The consolidated 1.0.0 workflow records the admissible
training domain, transformation state, assessment boundary, warnings,
hashes, and backend identity. A numerically attractive result does not
repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 8. Reference baseline

In package API governance, the reference baseline stage should preserve
the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **choosing a function without
checking its contract**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 9. Model complexity

In package API governance, the model complexity stage should preserve
the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **assuming source adapter equals
certified backend**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 10. Tuning and benchmarking

In package API governance, the tuning and benchmarking stage should
preserve the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **bypassing package-native
results**. The consolidated 1.0.0 workflow records the admissible
training domain, transformation state, assessment boundary, warnings,
hashes, and backend identity. A numerically attractive result does not
repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 11. Probabilistic prediction

In package API governance, the probabilistic prediction stage should
preserve the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **choosing a function without
checking its contract**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 12. Calibration and conformal reasoning

In package API governance, the calibration and conformal reasoning stage
should preserve the unit that was sampled, randomized, measured, or
externally validated. A central failure mode is **assuming source
adapter equals certified backend**. The consolidated 1.0.0 workflow
records the admissible training domain, transformation state, assessment
boundary, warnings, hashes, and backend identity. A numerically
attractive result does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 13. Diagnostics

In package API governance, the diagnostics stage should preserve the
unit that was sampled, randomized, measured, or externally validated. A
central failure mode is **bypassing package-native results**. The
consolidated 1.0.0 workflow records the admissible training domain,
transformation state, assessment boundary, warnings, hashes, and backend
identity. A numerically attractive result does not repair a design
violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 14. Typed uncertainty

In package API governance, the typed uncertainty stage should preserve
the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **choosing a function without
checking its contract**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 15. Explanation and stability

In package API governance, the explanation and stability stage should
preserve the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **assuming source adapter equals
certified backend**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 16. Protected external validation

In package API governance, the protected external validation stage
should preserve the unit that was sampled, randomized, measured, or
externally validated. A central failure mode is **bypassing
package-native results**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 17. Reporting

In package API governance, the reporting stage should preserve the unit
that was sampled, randomized, measured, or externally validated. A
central failure mode is **choosing a function without checking its
contract**. The consolidated 1.0.0 workflow records the admissible
training domain, transformation state, assessment boundary, warnings,
hashes, and backend identity. A numerically attractive result does not
repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 18. Reproducibility

In package API governance, the reproducibility stage should preserve the
unit that was sampled, randomized, measured, or externally validated. A
central failure mode is **assuming source adapter equals certified
backend**. The consolidated 1.0.0 workflow records the admissible
training domain, transformation state, assessment boundary, warnings,
hashes, and backend identity. A numerically attractive result does not
repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 19. Discrepant cases

In package API governance, the discrepant cases stage should preserve
the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **bypassing package-native
results**. The consolidated 1.0.0 workflow records the admissible
training domain, transformation state, assessment boundary, warnings,
hashes, and backend identity. A numerically attractive result does not
repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 20. Reviewer-oriented interpretation

In package API governance, the reviewer-oriented interpretation stage
should preserve the unit that was sampled, randomized, measured, or
externally validated. A central failure mode is **choosing a function
without checking its contract**. The consolidated 1.0.0 workflow records
the admissible training domain, transformation state, assessment
boundary, warnings, hashes, and backend identity. A numerically
attractive result does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### 21. Complete workflow

In package API governance, the complete workflow stage should preserve
the unit that was sampled, randomized, measured, or externally
validated. A central failure mode is **assuming source adapter equals
certified backend**. The consolidated 1.0.0 workflow records the
admissible training domain, transformation state, assessment boundary,
warnings, hashes, and backend identity. A numerically attractive result
does not repair a design violation.

Alternative methods should use shared admissible resamples and report
uncertainty or stability alongside point performance. Complexity is
added only when a diagnostic or scientific objective justifies it.
External-domain labels are never used to refit, retune, reselect
features, or recalibrate the model they are intended to assess.
Predictive explanation remains associational and non-causal unless a
separate causal design supports stronger interpretation.

``` r

library(sciModelFlowR)
smf_doctor()
head(smf_api_catalog())
smf_run_gold_validation()
```

A useful reporting habit at this stage is to state the scientific
target, the independent unit, the split geometry, the state learned from
training data, the metric or uncertainty target, and the evidence that
remained untouched until assessment. If a safeguard is overridden, the
reason belongs in the scientific record rather than only in code
comments.

### Final perspective

A strong analysis preserves a chain of evidence from design and data
identity through training, uncertainty, protected external validation,
and reporting. The objective is not to maximize algorithm count; it is
to make unsupported conclusions difficult to produce and supported
conclusions easy to audit.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.

#### Release-candidate guidance

Report the sampling unit, split geometry, preprocessing boundary,
feature-learning state, model role, uncertainty target, diagnostic
evidence, external-domain status, scientific warnings, and
reproducibility identifiers. Distinguish internal resampling, final
internal assessment, calibration data, conformal calibration data, and
truly external evidence. State explicitly when a layer of evidence is
absent. Gold results demonstrate software behavior under known synthetic
truth; they do not establish field efficacy.
