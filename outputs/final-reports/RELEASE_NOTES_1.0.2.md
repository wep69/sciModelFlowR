# Release notes — sciModelFlowR 1.0.2

**Type:** patch release of the Consolidated Scientific Release (base freeze 1.0.0).
**Date:** 2026-09-18.

## What changed

Five corrections reported by the audited tutorial of the 1.0.1 installed
library (`RELATORIO-AO-AUTOR.md`), each with a regression test in
`tests/testthat/test-regressions-102.R`:

1. **Portable persistence, high severity.** `smf_to_json()` now writes
   `na = "null"`; a portable bundle saved under the default preprocessing
   (`impute_numeric = "none"`) no longer fails at prediction with
   `argumento não-numérico para operador binário`. `smf_apply_preprocessor()`
   also tolerates textual/NULL imputation states from bundles written by
   earlier versions, and `.smf_atomic_write_json()` applies the same hygiene.
2. **Tuning contract, medium.** `smf_tune()` aborts with `smf_tuning_error`
   when an objective is not declared in `spec@metrics`, instead of producing an
   all-NA archive column and a silently empty selection; the `print` method
   distinguishes the two possible causes.
3. **PDP/ICE type, medium.** `smf_pdp()`/`smf_ice()` keep `value` numeric for
   numeric predictors (text only for factors), matching `smf_ale()`; this also
   removes the internal `as.character()` sensitivity to `OutDec`.
4. **Point intervals, low.** `smf_dist_interval()` refuses the `point`
   representation like `smf_dist_cdf()` does, instead of silently returning a
   degenerate `[m, m]` interval.
5. **Engine message, low.** The unknown-engine error lists the accepted engines
   and points to `smf_available_model_adapters()`.

The 246-symbol public API is unchanged; the 1.0.0 freeze and the 22
corrections of 1.0.1 remain the historical reference.

## Validation

- `R CMD check --as-cran`: **0 ERROR / 0 WARNING / 2 NOTEs** (accepted).
- testthat: 62 files, **322 pass / 0 fail**; installed from the tarball:
  `FAIL 0 | WARN 2 | SKIP 1 | PASS 322`.
- Gold 25/25, cross-language 25/25, reference tolerances ~1e-15.
- Static audit: 600/600.
- Vignettes 28/28, notebooks 27/27, pkgdown site 28/28 articles.

Full evidence: `outputs/final-reports/VALIDATION_RECORD_1.0.2.md`.

## Artefact

- `sciModelFlowR_1.0.2.tar.gz`
  SHA-256 `46755FD7445A0120D5DE921FF84E9AEE1C83E3E6396714D839F6E1215163AE1C`
