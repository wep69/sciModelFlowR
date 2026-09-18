# Package identity

**Status:** Accepted for 0.1.0  
**Date:** 2026-09-15

## Decision

Use `sciModelFlowR` as the R distribution name and `smf_` as the public constructor/high-level verb prefix. The R and Python packages are paired implementations with shared scientific semantics, not identical internals.

## Rationale

This decision preserves the package principle that scientific contracts belong to `sciModelFlowR`, while estimation is delegated to replaceable and explicitly certified backends. Changes that would break the scientific meaning of this decision require a new ADR and migration note.

## Consequences

- Public documentation must follow this decision.
- Tests must protect the relevant stable contract.
- Later modules may extend the contract but should not silently redefine it.
