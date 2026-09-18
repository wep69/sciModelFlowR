# Development helper for sciModelFlowR 0.5.0.
# This script is not executed during package installation.
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak", repos = "https://cloud.r-project.org")
}
core <- c("S7", "cli", "digest", "jsonlite", "rlang", "tibble", "vctrs", "withr", "yaml")
validation <- c("testthat", "devtools", "rcmdcheck", "covr", "pkgdown", "knitr", "rmarkdown", "quarto", "waldo", "vdiffr")
optional <- c("parsnip", "workflows", "recipes", "rsample", "spatialsample", "yardstick", "themis", "probably", "mlr3", "mlr3learners", "mlr3tuning", "mlr3mbo", "mlr3hyperband", "paradox", "bbotk", "xgboost", "glmnet", "ranger", "pls", "DALEX", "ingredients", "iml", "fastshap", "vip")
pak::pkg_install(c(core, validation, optional))
