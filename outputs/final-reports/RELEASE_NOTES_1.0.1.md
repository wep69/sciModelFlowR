# sciModelFlowR 1.0.1 — local validation patch

Patch release of the 1.0.0 Consolidated Scientific Release source freeze.
It ships the 22 documented corrections from the local validation campaign
(`DERIVED_PATCH_NOTES.md`). The 246-symbol public API is unchanged and the
1.0.0 freeze remains the historical reference.

## Highlights

- **Load/runtime blockers fixed**: reserved-word `repeat` in resampling,
  S7 print-method order for GP/BART, `Sys.info()[["model"]]` hardware probe,
  runtime guard for missing `torch` lazy modules, `:::` self-reference removed.
- **Scientific corrections**: reference gate now respects the holdout
  train/test scope; isotonic calibration fits on score-ordered pairs and never
  emits zero rows; `"linear"` alias accepted by the stats/tidymodels adapters;
  racing archive schema is homogeneous.
- **Serialization**: empty JSON arrays round-trip to typed empty vectors
  (fixes `DLGradientExplanation`/`ExplainSpec`/`DataSpec` across sessions).
- **Packaging/build**: `inst/gold` → `inst/gold_data` (R CMD build drops
  `*old` directories and silently removed the complete Gold suite from
  tarballs); topic-only `man/`; quarto vignette metadata so 28 HTML vignettes
  are built into `inst/doc`; clean NAMESPACE imports; `LICENSE` stub.
- **Teaching/validation material**: 27 notebooks execute against the release
  version; historical harnesses preserved with derived equivalents.

## Validation (Windows 11, R 4.6.0, Quarto 1.11.0)

- `R CMD check --as-cran`: **0 ERROR / 0 WARNING / 2 NOTEs** (accepted).
- `testthat`: 61 files, 299 pass / 0 fail (source and installed).
- Gold 25/25, cross-language 25/25, reference tolerances ~1e-15.
- 28/28 vignettes rendered, 27/27 notebooks executed, pkgdown site rebuilt.

The package is **not** claimed CRAN-ready. Historical 0.1.0–0.9.0 campaigns
remain `NOT RUN` here (their snapshots are not distributed with 1.0.x);
GPU/CUDA `SKIP`; ONNX `QUARANTINED`. Full evidence:
`outputs/final-reports/VALIDATION_RECORD_1.0.1.md`.

## Artefact

- `sciModelFlowR_1.0.1.tar.gz`
  SHA-256 `F395795E874E6CFEECDD1F52BDB5469339E5100CC9D6FA75EA9CE1EE07E90DB4`
- Source freeze 1.0.0 preserved: ZIP `9483b17f…`, TAR.GZ `ef684ad7…`.
