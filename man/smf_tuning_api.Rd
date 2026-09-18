\name{smf_tuning_api}
\alias{smf_param_dbl}
\alias{smf_param_int}
\alias{smf_param_fct}
\alias{smf_param_lgl}
\alias{smf_search_space}
\alias{smf_search_grid}
\alias{smf_search_random}
\alias{smf_tuning_spec}
\alias{smf_tune_objective}
\alias{smf_tune}
\alias{smf_nested_tune}
\alias{smf_pareto_front}
\alias{smf_select_compromise}
\alias{smf_benchmark_spec}
\alias{smf_benchmark}
\alias{smf_decide_benchmark}
\title{Scientific Hyperparameter Tuning and Benchmarking}
\description{Construct portable search spaces, execute design-aware hyperparameter optimization, separate inner model selection from outer generalization, analyze Pareto fronts, and benchmark candidate models on shared resamples.}
\details{The 0.4.0 tuning API blocks final-test roles from optimization. Multi-objective workflows return a Pareto set unless an explicit compromise rule is declared. Benchmarking does not define a universal winner by default. The package-native tuning engine is the reference implementation for this source release.}
\value{Constructors return S7 specification objects. Tuning and benchmark functions return package-native result objects containing archives, split provenance, scientific warnings, and reproducibility metadata.}
\seealso{\code{smf_resample_experiment}, \code{smf_experiment_spec}}
