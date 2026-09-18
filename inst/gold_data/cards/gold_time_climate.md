# gold_time_climate

## Scientific scenario

Synthetic monthly climate-like series containing trend, seasonality, and serial dependence. The dataset is included in 0.1.0 so time can be declared explicitly even though dependence-aware temporal resampling is implemented in 0.2.0.

## Known structure

The deterministic component contains a linear trend plus annual sine/cosine seasonality. Residual dependence follows an AR(1)-like recursion with coefficient 0.65.

## Validation target

Declaring `date` or `time_index` as time metadata must survive serialization. A random shuffled holdout should be treated as scientifically risky for forecasting-style claims.

## Pedagogical trap

A model can achieve strong random-split performance while leaking information across nearby times.

## Frozen artifact

- Seed: `260915`
- Generator version: `0.1.0`
- SHA-256: `84f8556151685f6deafed617f58349f714205a7c1b78f08d76b1cd746daf3804`
- This dataset is synthetic and is not empirical field evidence.
