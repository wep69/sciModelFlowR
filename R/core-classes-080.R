TrackingSpec <- S7::new_class(
  "TrackingSpec",
  properties = list(provider=S7::class_character, uri=S7::class_character,
    experiment=S7::class_character, tags=S7::class_any,
    artifact_mode=S7::class_character, parameters=S7::class_any),
  validator = function(self) {
    if (length(self@provider) != 1L || !self@provider %in% c("none","local","mlflow")) return("@provider must be none, local, or mlflow")
    if (length(self@experiment) != 1L || !nzchar(self@experiment)) return("@experiment must be non-empty")
    if (length(self@artifact_mode) != 1L || !self@artifact_mode %in% c("copy","reference")) return("@artifact_mode must be copy or reference")
    NULL
  }
)

PersistenceSpec <- S7::new_class(
  "PersistenceSpec",
  properties = list(schema_version=S7::class_character, mode=S7::class_character,
    checksum=S7::class_character, trusted_required=S7::class_logical,
    parameters=S7::class_any),
  validator = function(self) {
    if (length(self@schema_version) != 1L || !grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", self@schema_version)) return("@schema_version must use MAJOR.MINOR.PATCH")
    if (length(self@mode) != 1L || !self@mode %in% c("safe_preferred","portable_only","opaque_allowed")) return("@mode is not supported")
    if (length(self@checksum) != 1L || !self@checksum %in% c("sha256")) return("@checksum must be sha256")
    NULL
  }
)

DeploymentSpec <- S7::new_class(
  "DeploymentSpec",
  properties = list(adapter=S7::class_character, strict_schema=S7::class_logical,
    batch_size=S7::class_integer, parameters=S7::class_any),
  validator = function(self) {
    if (length(self@adapter) != 1L || !self@adapter %in% c("none","local","pins","vetiver","onnx")) return("@adapter is not supported")
    if (length(self@batch_size) != 1L || self@batch_size < 1L) return("@batch_size must be at least 1")
    NULL
  }
)

ScalabilitySpec <- S7::new_class(
  "ScalabilitySpec",
  properties = list(chunk_size=S7::class_integer, workers=S7::class_integer,
    execution=S7::class_character, checkpoint_every=S7::class_integer,
    parameters=S7::class_any),
  validator = function(self) {
    if (length(self@chunk_size) != 1L || self@chunk_size < 1L) return("@chunk_size must be at least 1")
    if (length(self@workers) != 1L || self@workers < 1L) return("@workers must be at least 1")
    if (length(self@execution) != 1L || !self@execution %in% c("sequential","parallel")) return("@execution must be sequential or parallel")
    NULL
  }
)

TrackerRun <- S7::new_class(
  "TrackerRun",
  properties = list(provider=S7::class_character, run_id=S7::class_character,
    external_id=S7::class_character, experiment=S7::class_character,
    path=S7::class_character, status=S7::class_character,
    started_at=S7::class_character, ended_at=S7::class_character,
    tags=S7::class_any, metadata=S7::class_any)
)

BundleValidationResult <- S7::new_class(
  "BundleValidationResult",
  properties = list(valid=S7::class_logical, path=S7::class_character,
    manifest=S7::class_any, checksums=S7::class_any,
    compatibility=S7::class_any, unsafe_components=S7::class_any,
    warnings=S7::class_any)
)

InferenceBundle <- S7::new_class(
  "InferenceBundle",
  properties = list(path=S7::class_character, manifest=S7::class_any,
    spec=S7::class_any, task=S7::class_any, preprocessing=S7::class_any,
    features=S7::class_any, model=S7::class_any, calibration=S7::class_any, schema=S7::class_any,
    labels=S7::class_any, safe=S7::class_logical, provenance=S7::class_any)
)

BatchPredictionResult <- S7::new_class(
  "BatchPredictionResult",
  properties = list(n_rows=S7::class_integer, n_batches=S7::class_integer,
    prediction=S7::class_any, batch_manifest=S7::class_any,
    resumed=S7::class_logical, provenance=S7::class_any)
)
