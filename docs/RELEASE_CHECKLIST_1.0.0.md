# sciModelFlowR 1.0.0 Release Checklist

## Source consolidation

0.9.0 frozen source used as base.

Public API copied into 1.0.0 stable freeze.

API diff initialized with no intended public changes.

Gold release manifest created.

Compatibility matrix created.

Static security review created.

Benchmark-baseline registry created.

pkgdown article map completed.

Release/migration documentation initialized.

## Deferred local certification after definitive source freeze

Install dependencies in a clean Windows validation environment.

Run historical validators 0.1.0 through 0.9.0.

Run 1.0.0 Gold/reference/differential/property/invariant suites.

Run optional backend certification matrix.

Run CPU and GPU Deep Learning tests where hardware is available.

Execute all notebooks and Quarto vignettes in clean environments.

Build pkgdown site and inspect links/examples.

Run R oldrel/release/devel checks on supported CI platforms.

Run `R CMD build`.

Run `R CMD check --as-cran` on the actual built tarball.

Review dependency/security advisories in final environment.

Freeze final benchmark timings and regression thresholds.

Generate source manifest, distribution SHA-256 files and independent
extraction comparison.

The source freeze is final. No unchecked runtime/certification item is
represented as passed; any corrective source change discovered later
requires a subsequent package version.
