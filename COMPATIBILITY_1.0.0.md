# sciModelFlowR 1.0.0 Compatibility Matrix

The machine-readable matrix is `inst/metadata/FINAL_COMPATIBILITY_MATRIX_1.0.0.csv`. At source initialization every runtime row remains **pending-final-local-validation**. This is intentional: adapter source availability is not equivalent to certification.

Certification must record exact R version, OS, package/backend version, CPU architecture, and GPU/CUDA information where relevant. Backends may be promoted from quarantine only after their dedicated numerical and integration tests pass. Failed optional backends remain available only at an explicitly experimental/advanced tier or remain quarantined.
