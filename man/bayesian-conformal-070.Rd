\name{bayesian-conformal-070}
\alias{bayesian-conformal-070}
\alias{smf_bayes_prior}
\alias{smf_bayes_fit}
\alias{smf_bayes_prior_predictive}
\alias{smf_bayes_draws}
\alias{smf_bayes_summary}
\alias{smf_bayes_epred}
\alias{smf_bayes_predict}
\alias{smf_bayes_diagnostic_flags}
\alias{smf_bayes_diagnose}
\alias{smf_bayes_pp_check}
\alias{smf_bayes_loo}
\alias{smf_bayes_compare}
\alias{smf_bayes_stacking}
\alias{smf_bart_fit}
\alias{smf_bart_predict}
\alias{smf_gp_fit}
\alias{smf_gp_predict}
\alias{smf_conformal_spec}
\alias{smf_conformal_fit}
\alias{smf_conformal_predict}
\alias{smf_conformal_coverage}
\alias{smf_conformal_diagnose}
\alias{smf_conformal_probably}
\alias{smf_conformal_predict_probably}
\alias{smf_uncertainty_descriptor}
\alias{smf_uncertainty_semantics}
\alias{smf_uncertainty_label}
\alias{smf_uncertainty_compare}
\alias{smf_uncertainty_validate}
\alias{smf_uncertainty_decompose}
\alias{smf_uncertainty_from_distribution}
\alias{smf_uncertainty_report}
\title{Bayesian modeling, conformal prediction, and typed uncertainty}
\description{
Version 0.7.0 interfaces for Bayesian reference and optional backend workflows,
posterior diagnostics and predictive checks, BART and Gaussian-process adapters,
conformal prediction, empirical coverage diagnostics, and typed uncertainty
semantics.
}
\details{
Bayesian intervals, posterior predictive intervals, bootstrap intervals,
confidence intervals, and conformal intervals are not treated as interchangeable.
The package-native conformal engine keeps calibration data separate from final
assessment data and records the exchangeability assumptions associated with
marginal coverage statements. Aleatoric/epistemic decomposition is returned only
when the implementation can identify the requested components. Optional Bayesian
and conformal backends remain subject to the consolidated local runtime and
numerical validation campaign.
}
\value{
Depending on the function, an S7 Bayesian/conformal result object, a
\code{PredictionDistribution}, an uncertainty descriptor/decomposition, or a
portable diagnostic/summary object.
}
\keyword{models}
