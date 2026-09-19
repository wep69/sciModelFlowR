# sciModelFlowR 1.0.0 Final Local Validation Campaign

This document is the entry point for the final Windows/local
certification campaign. It complements the version-specific validators
already distributed in `tools/`.

## Required order

1.  create a clean validation directory and record OS/R/toolchain
    versions;
2.  install core dependencies using `pak`/`renv` as appropriate;
3.  install optional backends in controlled groups;
4.  execute the historical validators from 0.1.0 through 0.9.0;
5.  execute `tools/validate_1.0.0.R`;
6.  run testthat,
    numerical/Gold/reference/differential/property/invariant suites;
7.  execute notebooks and Quarto vignettes in clean sessions;
8.  run CPU Deep Learning tests, then GPU/CUDA tests when hardware is
    available;
9.  validate persistence/bundle security, tracking, deployment adapters
    and batch-resume pathways;
10. build pkgdown and inspect examples/links;
11. run cross-platform CI on R oldrel/release/devel;
12. run `R CMD build` and `R CMD check --as-cran` against the actual
    tarball;
13. update compatibility, backend certification, benchmark and security
    metadata;
14. only then freeze final source/distribution manifests and hashes.

The final release record must distinguish PASS, FAIL, SKIP/UNAVAILABLE,
and QUARANTINED. Missing optional hardware or services do not justify a
false PASS.
