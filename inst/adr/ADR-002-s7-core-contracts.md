# S7 core contracts

**Status:** Accepted for 0.1.0  
**Date:** 2026-09-15

## Decision

Use S7 for package-native specifications, result envelopes, capability sets, warning records, uncertainty descriptors, and future prediction-distribution objects. Use standard S3 methods where they improve ordinary R ergonomics.

## Rationale

This decision preserves the package principle that scientific contracts belong to `sciModelFlowR`, while estimation is delegated to replaceable and explicitly certified backends. Changes that would break the scientific meaning of this decision require a new ADR and migration note.

## Consequences

- Public documentation must follow this decision.
- Tests must protect the relevant stable contract.
- Later modules may extend the contract but should not silently redefine it.
