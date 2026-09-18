\name{tracking-persistence-080}
\alias{smf_tracking_spec}
\alias{smf_tracker_local}
\alias{smf_tracker_mlflow}
\alias{smf_start_run}
\alias{smf_log_metric}
\alias{smf_log_params}
\alias{smf_log_artifact}
\alias{smf_log_result}
\alias{smf_end_run}
\alias{smf_list_runs}
\alias{smf_get_run}
\alias{smf_persistence_spec}
\alias{smf_deployment_spec}
\alias{smf_scalability_spec}
\alias{smf_save_bundle}
\alias{smf_validate_bundle}
\alias{smf_load_bundle}
\alias{smf_predict_bundle}
\alias{smf_bundle_info}
\alias{smf_hardware_info}
\alias{smf_chunk_plan}
\alias{smf_data_iterator}
\alias{smf_iterator_next}
\alias{smf_iterator_reset}
\alias{smf_map_iterator}
\alias{smf_batch_predict}
\alias{smf_pins_publish_bundle}
\alias{smf_pins_fetch_bundle}
\alias{smf_vetiver_model}
\alias{smf_vetiver_pin_write}
\alias{smf_write_plumber}
\alias{smf_export_onnx}
\title{Tracking, safe persistence, deployment, and scalable inference}
\description{Version 0.8.0 APIs for local and optional MLflow tracking, checksum-verified inference bundles, explicit trust boundaries for opaque serialization, optional pins/vetiver deployment adapters, hardware provenance, deterministic batch prediction, resumable checkpoints, and iterator-based processing.}
\details{Portable safe-state export is intentionally limited to fitted pipelines whose semantics can be represented without opaque R serialization. Opaque bundles are checksum-verified but require explicit \code{trusted = TRUE} before deserialization. Optional integrations never block the local core path.}
\value{Package-native specification, tracker, bundle, validation, or batch-prediction objects as appropriate.}
\examples{
\dontrun{
tracker <- smf_tracker_local(tempfile(), "demo")
run <- smf_start_run(tracker)
run <- smf_end_run(run, "finished")
}
}
