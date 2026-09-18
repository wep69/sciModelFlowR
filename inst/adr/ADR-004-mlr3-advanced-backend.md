# Advanced tuning backend

**Status:** Accepted for 0.1.0  
**Date:** 2026-09-15

## Decision

Reserve mlr3 and its tuning ecosystem for advanced optional orchestration such as complex nested resampling and multiobjective tuning. It is not a core dependency.

## Rationale

This decision preserves the package principle that scientific contracts belong to `sciModelFlowR`, while estimation is delegated to replaceable and explicitly certified backends. Changes that would break the scientific meaning of this decision require a new ADR and migration note.

## Consequences

- Public documentation must follow this decision.
- Tests must protect the relevant stable contract.
- Later modules may extend the contract but should not silently redefine it.
