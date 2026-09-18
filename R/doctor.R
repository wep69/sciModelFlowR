#' Inspect the local sciModelFlowR environment
#' @export
smf_doctor <- function() {
  optional <- c("recipes","rsample","spatialsample","glmnet","ranger","pls","parsnip","workflows","yardstick","mlr3","xgboost","lightgbm","catboost","torch","luz","keras3","brms","cmdstanr","posterior","loo","DALEX","iml","fastshap","ggplot2","quarto","mlflow","pins","vetiver","plumber")
  avail <- vapply(optional,requireNamespace,quietly=TRUE,FUN.VALUE=logical(1))
  data.frame(component=c("R","sciModelFlowR",optional),available=c(TRUE,TRUE,unname(avail)),version=c(as.character(getRversion()),.smf_version(),vapply(optional,function(p) if(requireNamespace(p,quietly=TRUE)) as.character(utils::packageVersion(p)) else NA_character_,character(1))),status=c("core","core",ifelse(avail,"optional-available","optional-unavailable")),row.names=NULL)
}
