# Gold data generation

The distributed Gold CSV files are frozen synthetic validation fixtures. Their authoritative hashes are stored in `inst/gold_data/gold_hashes.csv`. They are development and validation assets, not empirical scientific evidence.

The original byte-exact generator for the six historical 0.1.0 fixtures is not distributed in this source snapshot; those files therefore remain immutable historical fixtures identified by their SHA-256 hashes. Later releases should not claim otherwise.

Version 0.5.0 includes an R generator for `gold_xai_stability`. Version 0.7.0 includes the byte-exact Python/NumPy generator `generate-gold-bayes-conformal.py` for `gold_bayesian_linear` and `gold_conformal_regression`; Python is not a runtime dependency of the R package. `reference-formulas-gold-bayes-conformal.R` documents the corresponding scientific formulas but is not a byte-exact RNG reproduction.

If a generator, RNG algorithm, draw order, formula, row order, numeric formatting, or expected scientific property changes, create a new Gold-data version and regenerate the hash manifest deliberately. Never overwrite a release Gold fixture silently.
