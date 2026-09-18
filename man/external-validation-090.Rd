\name{external-validation-090}
\alias{smf_external_validate}
\alias{smf_compare_validation_domains}
\title{Protected external validation}
\description{Applies a frozen fitted workflow to a protected external domain without refitting preprocessing, features, model, or calibration.}
\usage{
smf_external_validate(result, external_data, domain_name = "external", metrics = NULL, truth = NULL, id_column = NULL)
smf_compare_validation_domains(internal_result, external_result)
}
\details{External-domain labels are used only for evaluation. Predictor-support diagnostics and structured warnings are retained separately from internal development evidence.}
