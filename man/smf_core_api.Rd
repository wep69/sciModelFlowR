\name{smf_core_api}
\alias{smf_apply_preprocessor}
\alias{smf_audit_data}
\alias{smf_backend_capabilities}
\alias{smf_backend_object}
\alias{smf_bayesian_spec}
\alias{smf_bootstrap_spec}
\alias{smf_capabilities}
\alias{smf_data_hash}
\alias{smf_data_spec}
\alias{smf_dataset_card}
\alias{smf_design_spec}
\alias{smf_design_summary}
\alias{smf_detect_leakage}
\alias{smf_diagnose}
\alias{smf_dl_spec}
\alias{smf_doctor}
\alias{smf_evaluate}
\alias{smf_experiment_spec}
\alias{smf_fit_experiment}
\alias{smf_fit_preprocessor}
\alias{smf_from_json}
\alias{smf_from_list}
\alias{smf_hash}
\alias{smf_holdout_split}
\alias{smf_import_split_manifest}
\alias{smf_list_datasets}
\alias{smf_load_dataset}
\alias{smf_manifest}
\alias{smf_metric_spec}
\alias{smf_missingness_report}
\alias{smf_model_spec}
\alias{smf_plot}
\alias{smf_predict}
\alias{smf_preprocess_provenance}
\alias{smf_preprocess_spec}
\alias{smf_probabilistic_spec}
\alias{smf_register_backend}
\alias{smf_report}
\alias{smf_reproducibility_spec}
\alias{smf_require_capability}
\alias{smf_resampling_spec}
\alias{smf_rng_info}
\alias{smf_run_gold_validation}
\alias{smf_save_manifest}
\alias{smf_spec_hash}
\alias{smf_split_manifest}
\alias{smf_task_spec}
\alias{smf_to_json}
\alias{smf_to_list}
\alias{smf_to_yaml}
\alias{smf_uncertainty_spec}
\alias{smf_validate_design}
\alias{smf_validate_schema}
\alias{smf_validate_split}
\alias{smf_warning_record}
\alias{smf_with_seed}
\title{sciModelFlowR Core Scientific Workflow API}
\description{Construct, validate, audit, fit, diagnose, serialize, and reproduce design-aware scientific workflows. The core API preserves the stable design, leakage, preprocessing, result, and provenance contracts introduced in the foundational releases.}
\usage{
smf_task_spec(kind = "regression", target, positive_label = NULL, objective = character())
smf_data_spec(target, predictors = character(), id_column = character(), ...)
smf_design_spec(id_column = character(), group_columns = character(), ...)
smf_experiment_spec(task, data, design, preprocessing, resampling, model, ...)
smf_audit_data(data, spec, design = NULL)
smf_fit_experiment(spec, data, split = NULL)
smf_diagnose(result)
smf_manifest(x)
smf_doctor()
}
\details{The public API is organized around explicit scientific specifications. Data roles and design are declared before validation and model fitting. Managed preprocessing is fitted on training observations only. Heavy machine-learning, Bayesian, and Deep-Learning backends are optional and are not loaded by the core. See the package vignettes for complete workflows, assumptions, failure modes, and release scope.}
\value{Constructors return S7 specification objects. Audit, split, fit, diagnostic, and manifest functions return package-native result objects or portable data structures as documented in the vignettes.}
\seealso{\code{vignette("v01-foundations-to-advanced-scientific-modeling", package = "sciModelFlowR")}}
