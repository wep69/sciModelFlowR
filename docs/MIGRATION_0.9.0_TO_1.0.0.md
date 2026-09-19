# sciModelFlowR Migration Guide: 0.9.0 to 1.0.0

## Core rule

Version 1.0.0 is the certified/consolidated form of the 0.9.0 scientific
grammar, not a redesign. The public export set remains at 246 functions
at initialization, and scientific semantics are intended to remain
unchanged unless the final validation campaign discovers a blocker that
cannot be fixed internally.

## User scripts

Scripts written against 0.9.0 should not require symbol renaming. Users
should nevertheless rerun Gold/reference checks after installing 1.0.0
and record the new package/version manifest. Serialized portable bundles
should be validated with
[`smf_validate_bundle()`](https://wep69.github.io/sciModelFlowR/reference/tracking-persistence-080.md)
before loading. Opaque R bundles require explicit trust as before.

## Backend status

Optional backend adapters remain quarantined until actual local
certification. A backend becoming certified does not change the
package-native result grammar. A backend failing certification should
not force users to rewrite workflows; it changes only
capability/certification status.

## Deprecation

No 0.9.0 public symbol is intentionally removed in 1.0.0. Future 1.x
changes follow `DEPRECATION_POLICY.md` and require a documented
lifecycle, replacement/rationale, and migration path for semantic
changes.
