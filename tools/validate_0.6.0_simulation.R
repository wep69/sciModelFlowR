# sciModelFlowR 0.6.0 numerical/simulation validation entry point.
# Execute only during the consolidated local validation campaign.
if (!requireNamespace("torch", quietly=TRUE)) {
  message("torch unavailable: simulation gates skipped, not passed.")
} else {
  d <- smf_load_dataset("gold_dl_nonlinear")
  x <- as.matrix(d[,c("x1","x2")]); y <- d$y
  seeds <- c(260915L,260916L,260917L)
  fits <- lapply(seeds,function(s) smf_dl_train(x[1:320,],y[1:320],architecture=smf_mlp(2,hidden=c(32L,16L)),
    validation=list(x=x[321:400,],y=y[321:400]),epochs=10L,batch_size=32L,device="cpu",seed=s))
  ens <- smf_dl_ensemble(fits=fits,seeds=seeds)
  pd <- smf_dl_predict_distribution(ens,x[401:480,],method="ensemble")
  stopifnot(S7::S7_inherits(pd,sciModelFlowR:::PredictionDistribution))
  message("Repeat this scenario with pre-specified RMSE, coverage, calibration, CPU/GPU and checkpoint tolerances before certification.")
}
