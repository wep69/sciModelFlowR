# sciModelFlowR 1.0.0 Release Notes

## Purpose

The 1.0.0 Consolidated Scientific Release turns the 0.9.0
release-candidate grammar into a stable 1.x contract. The release is
intentionally conservative: certification evidence, compatibility
metadata, security review, release manifests, documentation
synchronization, and migration guidance are prioritized over new
algorithms.

## Stable scientific contracts

Design before algorithm; training-only learning; no tuning on final test
data; typed uncertainty; explicit backend capabilities; package-native
result objects; mandatory provenance; diagnostics before interpretation;
observed-data visibility; no causal interpretation from predictive XAI;
explicit trust for opaque serialization; and reproducibility manifests
remain the governing contracts.

## API

The 246 public exports frozen at 0.9.0 are promoted to the stable 1.x
contract. `API_DIFF_0.9.0_TO_1.0.0.csv` is intentionally all `unchanged`
in the definitive source freeze.

## Validation status

Source consolidation does not imply runtime certification. The final
local campaign must execute the historical version validators, 1.0.0
release validator, Gold/numerical/reference/differential suites,
optional backends, CPU/GPU paths, documentation builds, cross-platform
checks, and `R CMD check --as-cran`.

## Freeze status

Version 1.0.0 is frozen as the **Consolidated Scientific Release
source**. Runtime certification remains a distinct evidence layer and is
not inferred from the frozen source structure. Any source correction
after this point requires a subsequent version.
