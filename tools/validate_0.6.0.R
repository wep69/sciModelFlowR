# sciModelFlowR 0.6.0 runtime validation entry point.
# Execute only during the consolidated local validation campaign.
stopifnot(as.character(utils::packageVersion("sciModelFlowR")) == "0.6.0")
stopifnot(all(c("gold_dl_nonlinear","gold_dl_sequence") %in% smf_list_datasets()))

# Architecture and serialization contracts.
a <- smf_mlp(2, hidden=c(16L,8L), output_dim=1L)
stopifnot(S7::S7_inherits(a, sciModelFlowR:::DLArchitecture))
a2 <- smf_from_json(smf_to_json(a))
stopifnot(identical(a2@kind,"mlp"), identical(a2@input_shape,2L))

# Leakage boundary.
err <- try(sciModelFlowR:::.smf_dl_validation_role("final_test"), silent=TRUE)
stopifnot(inherits(err,"try-error"))

# Gold contracts.
d <- smf_load_dataset("gold_dl_nonlinear")
stopifnot(nrow(d)==480L, all(d$sigma_truth>0))
s <- smf_load_dataset("gold_dl_sequence")
stopifnot(nrow(s)==160L, sum(grepl("^t[0-9]{2}$",names(s)))==24L)

if (requireNamespace("torch", quietly=TRUE)) {
  x <- as.matrix(d[,c("x1","x2")]); y <- d$y
  fit <- smf_dl_train(x[1:192,],y[1:192],architecture=smf_mlp(2,hidden=8L),
    validation=list(x=x[193:240,],y=y[193:240]),epochs=3L,batch_size=32L,device="cpu")
  p <- smf_dl_predict(fit,x[241:260,])
  stopifnot(length(p)==20L || nrow(as.matrix(p))==20L)
}

message("sciModelFlowR 0.6.0 runtime validation script completed.")
