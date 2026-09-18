# sciModelFlowR 1.0.0 Security Review

## Status

This is the static source review performed at initialization of the 1.0.0 Consolidated Scientific Release. It does not replace runtime dependency/advisory scanning or deployment-environment hardening.

## Threat boundaries

The package distinguishes portable metadata/state from opaque backend-native serialization. Portable bundles are checksum-verified and schema-versioned. Opaque R objects are not treated as safe interchange; `smf_load_bundle()` validates checksums and then requires explicit `trusted = TRUE` before any `readRDS()` call. This is a security boundary, not a convenience flag.

The static scan found no direct `system()`, `system2()`, `shell()`, `eval(parse())`, `source()`, or `download.file()` call in package R source. Deployment adapters are optional. ONNX export is deliberately not certified by existence of a file; a caller-supplied exporter is required and prediction equivalence must be validated separately.

## Findings

1. **Opaque serialization**: guarded in source; remains high-risk if users override trust for untrusted artifacts.
2. **Checksums**: SHA-256 manifests protect integrity, not authenticity. Signed release artifacts remain an external release-engineering option.
3. **Schema compatibility**: major bundle-schema incompatibility is blocked and requires explicit migration.
4. **Plumber deployment**: generated endpoint code does not provide production authentication, TLS termination, rate limiting, secrets management, or network policy. Those are deployment responsibilities.
5. **External services**: MLflow, pins, vetiver and Plumber remain optional and quarantined until final local certification.
6. **Dependency advisories**: must be checked in the final release environment because advisory state is time-sensitive.

## Release blockers still requiring execution

- install/check on supported R environments;
- dependency and security-advisory review using the final lock/environment;
- bundle tamper/trust tests under R;
- production deployment review for any public service;
- verification that generated archives/manifests match the exact final source tree.
