# gold_linear_regression

## Scientific scenario

Synthetic agronomic yield response with independent observational units and a Gaussian linear data-generating process. The dataset is intended to validate schema handling, holdout splitting, training-only preprocessing, reference linear-model adapters, prediction metrics, serialization, and reproducibility manifests.

## Variables

- `obs_id`: stable observation identifier.
- `nitrogen`: nitrogen dose, arbitrary teaching units.
- `rainfall`: seasonal rainfall, mm-like teaching scale.
- `soil_n`: soil nitrogen indicator.
- `yield`: continuous synthetic response.

## Known truth

The generator uses an intercept of 32, slopes 0.18, 0.012, and 4.5, and Gaussian noise with standard deviation 3.5. Finite-sample estimates are not expected to equal the generating values exactly.

## Pedagogical traps

Do not compare coefficients fitted after scaling predictors directly with unscaled generating coefficients. Do not use the held-out test rows to estimate preprocessing statistics.

## Frozen artifact

- Seed: `260915`
- Generator version: `0.1.0`
- SHA-256: `c970ec3fd4c8ae84aea857b6b01acbba9e48653b433e608ba924e2f481f51fc0`
- This dataset is synthetic and is not empirical field evidence.
