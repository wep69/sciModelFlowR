# Scientific Hyperparameter Tuning and Benchmarking

Construct portable search spaces, execute design-aware hyperparameter
optimization, separate inner model selection from outer generalization,
analyze Pareto fronts, and benchmark candidate models on shared
resamples.

## Details

The 0.4.0 tuning API blocks final-test roles from optimization.
Multi-objective workflows return a Pareto set unless an explicit
compromise rule is declared. Benchmarking does not define a universal
winner by default. The package-native tuning engine is the reference
implementation for this source release.

## Value

Constructors return S7 specification objects. Tuning and benchmark
functions return package-native result objects containing archives,
split provenance, scientific warnings, and reproducibility metadata.

## See also

`smf_resample_experiment`, `smf_experiment_spec`
