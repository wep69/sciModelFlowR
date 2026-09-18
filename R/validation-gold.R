#' Validate frozen Gold hashes and basic invariants
#' @export
smf_run_gold_validation <- function(stop_on_failure=FALSE) {
  manifest_path <- system.file("gold","gold_hashes.csv",package="sciModelFlowR")
  if(!nzchar(manifest_path)) manifest_path <- file.path("inst","gold","gold_hashes.csv")
  man <- utils::read.csv(manifest_path,stringsAsFactors=FALSE)
  res <- lapply(seq_len(nrow(man)), function(i) {
    nm <- man$dataset[[i]]
    path <- system.file("extdata","gold",paste0(nm,".csv"),package="sciModelFlowR")
    if(!nzchar(path)) path <- file.path("inst","extdata","gold",paste0(nm,".csv"))
    got <- digest::digest(file=path,algo="sha256",serialize=FALSE)
    data.frame(dataset=nm,expected=man$sha256[[i]],observed=got,passed=identical(tolower(got),tolower(man$sha256[[i]])),row.names=NULL)
  })
  out <- do.call(rbind,res)
  if(stop_on_failure && any(!out$passed)) cli::cli_abort("One or more Gold hashes failed validation.")
  out
}
