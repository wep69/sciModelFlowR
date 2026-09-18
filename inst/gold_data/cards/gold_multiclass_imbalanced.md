# gold_multiclass_imbalanced

## Scientific scenario

Synthetic three-class classification data with deliberately unequal class prevalence and overlapping predictors. The dataset is intended for multiclass probability prediction, imbalance-aware validation, fold-safe sampling, calibration, threshold/rule discussions, and probability scoring.

## Known generator

Three latent linear scores are converted to class probabilities with a softmax transformation. The intercept for class `C` is substantially lower than for classes `A` and `B`, making `C` the rare class while preserving predictor-dependent overlap.

## Validation target

A valid workflow should preserve all classes in resampling where feasible, apply imbalance handling only within analysis folds, return one probability column per class, and keep each probability row normalized to one within numerical tolerance. Probability calibration and PR-oriented metrics should be evaluated out of sample.

## Pedagogical trap

Columns `true_p_A`, `true_p_B`, and `true_p_C` are generator metadata. They are frozen to support numerical checks and must not be used as ordinary predictors. Using them as features is direct generator leakage.

## Frozen artifact

- Seed: `260915`
- Generator version: `0.3.0`
- Rows: `600`
- SHA-256: `ec0fff66e3da8341c5595a2cd8d28e0c1921371ba54e27cc02d49038563fcc09`
- This dataset is synthetic and is not empirical field evidence.
