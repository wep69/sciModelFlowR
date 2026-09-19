# Tracking, safe persistence, deployment, and scalable inference

Version 0.8.0 APIs for local and optional MLflow tracking,
checksum-verified inference bundles, explicit trust boundaries for
opaque serialization, optional pins/vetiver deployment adapters,
hardware provenance, deterministic batch prediction, resumable
checkpoints, and iterator-based processing.

## Details

Portable safe-state export is intentionally limited to fitted pipelines
whose semantics can be represented without opaque R serialization.
Opaque bundles are checksum-verified but require explicit
`trusted = TRUE` before deserialization. Optional integrations never
block the local core path.

## Value

Package-native specification, tracker, bundle, validation, or
batch-prediction objects as appropriate.

## Examples

``` r
if (FALSE) { # \dontrun{
tracker <- smf_tracker_local(tempfile(), "demo")
run <- smf_start_run(tracker)
run <- smf_end_run(run, "finished")
} # }
```
