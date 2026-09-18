# R-Python Cross-Language Validation Contract

Cross-language parity concerns scientific quantities and portable contracts, not identical RNG streams or backend internals. Neutral fixtures live under `inst/crosslang/` and cover schemas, frozen datasets, split manifests, expected metrics/predictions, tolerances, uncertainty semantics, reporting semantics, and algorithm-version identifiers.

The local certification campaign should execute the R and Python reference workflows against the same frozen identifiers, compare deterministic reference computations within declared tolerances, verify probability normalization and interval ordering, and document backend-specific differences rather than forcing false equivalence.
