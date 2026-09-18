# gold_binary_calibration

## Scientific scenario

Synthetic binary event data generated from a logistic model with known event probabilities. The dataset supports probability prediction, calibration checks, Brier scoring, and leakage-safe classification examples.

## Known truth

`logit(p) = -0.4 + 1.1*x1 - 0.8*x2`.

## Validation target

A correctly specified logistic model should reproduce the ranking and broad calibration structure in sufficiently large samples. The column `true_probability` is generator metadata and must not be used as a predictor in ordinary prediction exercises.

## Pedagogical trap

Including `true_probability` as a predictor creates generator leakage and produces an unrealistically easy prediction problem.

## Frozen artifact

- Seed: `260915`
- Generator version: `0.1.0`
- SHA-256: `ab56b19a9352064e82c85d3b2bfc57c77a0486c3fc6ff665ac0b7dcfc7b98a90`
- This dataset is synthetic and is not empirical field evidence.
