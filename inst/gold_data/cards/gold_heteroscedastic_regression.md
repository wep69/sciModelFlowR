# gold_heteroscedastic_regression

## Scientific scenario

Synthetic continuous response with predictor-dependent residual scale. The mean structure is linear but the conditional variance increases with `x`. Version 0.1.0 uses this dataset mainly for auditing and diagnostic preparation; distributional and probabilistic modeling is introduced later.

## Known truth

Conditional mean: `10 + 2*x - 0.7*z`. Conditional residual standard deviation: `0.6 + 0.35*x`.

## Validation target

A mean-only model should recover the broad location structure, but residual magnitude should increase across `x`. A future probabilistic model should be rewarded for representing the changing scale rather than only the predictive mean.

## Pedagogical trap

A small RMSE does not establish homoscedasticity or calibrated predictive uncertainty.

## Frozen artifact

- Seed: `260915`
- Generator version: `0.1.0`
- SHA-256: `d58c668a556c964f105dc2ac8514fa9bb34089d9d52095b9568a6ec5d2791987`
- This dataset is synthetic and is not empirical field evidence.
