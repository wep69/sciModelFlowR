# gold_xai_stability

## Scientific scenario

Deterministic synthetic regression fixture for explainability and explanation-stability validation. `signal_primary` drives the response, `signal_correlated` is intentionally highly correlated with it, and `weak_feature` has a much smaller direct effect. The fixture is not empirical evidence.

## Known truth

`response = 10 + 5 * signal_primary + 0.5 * weak_feature + deterministic low-amplitude oscillatory noise`. `signal_correlated` is constructed as `0.96 * signal_primary + 0.04 * sin(i * 0.37)` and therefore should trigger the correlated-feature XAI warning. Because permutation methods disturb the joint distribution, importance may be redistributed between the two correlated predictors; the package must not label that redistribution as a causal effect.

## Expected properties

- `signal_primary` and `signal_correlated` have absolute Pearson correlation above 0.95.
- package-native XAI must emit the correlated-feature warning at threshold 0.8.
- explanations must carry `causal_interpretation = FALSE`.
- explanation-stability summaries must be reproducible for frozen resampling manifests and seeds.
- source-feature tracing remains available after preprocessing.

## Frozen artifact

- Generator: deterministic index-based formula, no RNG required.
- Generator version: `0.5.0`.
- Rows: 240.
- SHA-256: `021c090612dc929662bb514ef162239548d1664d8d7c836a414398fcd813fd8a`.
