# Release-candidate result classes introduced in 0.9.0.

ExternalValidationResult <- S7::new_class(
  "ExternalValidationResult",
  properties = list(
    domain_name = S7::class_character,
    metrics = S7::class_any,
    predictions = S7::class_any,
    truth = S7::class_any,
    diagnostics = S7::class_any,
    warnings = S7::class_any,
    provenance = S7::class_any
  )
)

ReportingResult <- S7::new_class(
  "ReportingResult",
  properties = list(
    format = S7::class_character,
    path = S7::class_character,
    content = S7::class_any,
    tables = S7::class_any,
    figures = S7::class_any,
    checklist = S7::class_any,
    manifest = S7::class_any
  )
)

ReleaseCandidateAudit <- S7::new_class(
  "ReleaseCandidateAudit",
  properties = list(
    api_hash = S7::class_character,
    n_exports = S7::class_integer,
    backend_matrix = S7::class_any,
    gold = S7::class_any,
    crosslang = S7::class_any,
    blockers = S7::class_any,
    runtime_certified = S7::class_logical,
    status = S7::class_character
  )
)
