# sciModelFlowR Core Scientific Workflow API

Construct, validate, audit, fit, diagnose, serialize, and reproduce
design-aware scientific workflows. The core API preserves the stable
design, leakage, preprocessing, result, and provenance contracts
introduced in the foundational releases.

## Details

The public API is organized around explicit scientific specifications.
Data roles and design are declared before validation and model fitting.
Managed preprocessing is fitted on training observations only. Heavy
machine-learning, Bayesian, and Deep-Learning backends are optional and
are not loaded by the core. See the package vignettes for complete
workflows, assumptions, failure modes, and release scope.

## Value

Constructors return S7 specification objects. Audit, split, fit,
diagnostic, and manifest functions return package-native result objects
or portable data structures as documented in the vignettes.

## See also

[`vignette("v01-foundations-to-advanced-scientific-modeling", package = "sciModelFlowR")`](https://wep69.github.io/sciModelFlowR/articles/v01-foundations-to-advanced-scientific-modeling.md)
