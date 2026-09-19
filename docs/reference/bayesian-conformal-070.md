# Bayesian modeling, conformal prediction, and typed uncertainty

Version 0.7.0 interfaces for Bayesian reference and optional backend
workflows, posterior diagnostics and predictive checks, BART and
Gaussian-process adapters, conformal prediction, empirical coverage
diagnostics, and typed uncertainty semantics.

## Details

Bayesian intervals, posterior predictive intervals, bootstrap intervals,
confidence intervals, and conformal intervals are not treated as
interchangeable. The package-native conformal engine keeps calibration
data separate from final assessment data and records the exchangeability
assumptions associated with marginal coverage statements.
Aleatoric/epistemic decomposition is returned only when the
implementation can identify the requested components. Optional Bayesian
and conformal backends remain subject to the consolidated local runtime
and numerical validation campaign.

## Value

Depending on the function, an S7 Bayesian/conformal result object, a
`PredictionDistribution`, an uncertainty descriptor/decomposition, or a
portable diagnostic/summary object.
