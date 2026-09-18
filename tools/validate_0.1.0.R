args <- commandArgs(trailingOnly = TRUE)
pkg <- if (length(args)) normalizePath(args[[1]], mustWork = TRUE) else normalizePath(".", mustWork = TRUE)

cat("sciModelFlowR 0.1.0 local validation\n")
cat("Package:", pkg, "\n")
cat("R:", R.version.string, "\n\n")

needed <- c("S7","cli","digest","jsonlite","rlang","tibble","vctrs","withr","yaml","testthat","devtools","rcmdcheck")
missing <- needed[!vapply(needed, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing)) stop("Install missing validation packages first: ", paste(missing, collapse = ", "))

old <- setwd(pkg); on.exit(setwd(old), add = TRUE)

cat("[1] document\n")
devtools::document(roclets = c("rd", "namespace"))

cat("[2] unit/integration/numerical tests\n")
devtools::test(stop_on_failure = TRUE)

cat("[3] load all\n")
devtools::load_all(quiet = FALSE)

cat("[4] Gold hashes\n")
print(smf_run_gold_validation(stop_on_failure = TRUE))

cat("[5] end-to-end reference workflow\n")
d <- smf_load_dataset("gold_linear_regression")
spec <- smf_experiment_spec(
  task = smf_task_spec("regression", "yield"),
  data = smf_data_spec("yield", c("nitrogen","rainfall","soil_n"), id_column = "obs_id"),
  design = smf_design_spec(id_column = "obs_id", experimental_unit = "obs_id"),
  preprocessing = smf_preprocess_spec("median", center = TRUE, scale = TRUE),
  resampling = smf_resampling_spec("holdout", train_prop = .8, seed = 260915L),
  model = smf_model_spec("linear_regression", "stats"),
  metrics = list(smf_metric_spec("rmse"), smf_metric_spec("mae")),
  reproducibility = smf_reproducibility_spec(260915L)
)
a <- smf_fit_experiment(spec, d)
b <- smf_fit_experiment(spec, d)
stopifnot(identical(a@split@hash, b@split@hash))
stopifnot(isTRUE(all.equal(a@prediction@estimate, b@prediction@estimate, tolerance = 1e-12)))
print(a)

cat("[6] leakage blocker\n")
bad <- d; bad$yield_copy <- bad$yield
bad_spec <- smf_experiment_spec(
  task = smf_task_spec("regression", "yield"),
  data = smf_data_spec("yield", c("nitrogen","rainfall","soil_n","yield_copy"), id_column = "obs_id"),
  design = smf_design_spec(id_column = "obs_id"),
  preprocessing = smf_preprocess_spec(),
  resampling = smf_resampling_spec("holdout"),
  model = smf_model_spec("linear_regression", "stats")
)
blocked <- tryCatch({smf_fit_experiment(bad_spec,bad); FALSE}, smf_leakage_error = function(e) TRUE, error = function(e) inherits(e,"smf_leakage_error"))
stopifnot(blocked)

cat("[7] R CMD check via rcmdcheck\n")
res <- rcmdcheck::rcmdcheck(path = pkg, args = "--as-cran", error_on = "error")
print(res)
cat("Validation completed. Review all warnings and notes manually before release.\n")
