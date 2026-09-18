# sciModelFlowR 0.8.0 scalability and optional-adapter validation
library(sciModelFlowR)
d <- smf_load_dataset("gold_linear_regression")
spec <- smf_experiment_spec(
  smf_task_spec("regression","yield"),
  smf_data_spec("yield",c("nitrogen","rainfall","soil_n"),id_column="obs_id"),
  smf_design_spec(id_column="obs_id"),
  smf_preprocess_spec("median",TRUE,TRUE),
  smf_resampling_spec("holdout",seed=808L),
  smf_model_spec("linear_regression","stats")
)
r <- smf_fit_experiment(spec,d); bp <- tempfile("bundle-"); smf_save_bundle(r,bp,"portable"); b <- smf_load_bundle(bp)
reference <- as.numeric(smf_predict_bundle(b,d))
for(bs in c(1L,7L,31L,1000L)) {
  z <- smf_batch_predict(b,d,batch_size=bs)
  stopifnot(isTRUE(all.equal(reference,z@prediction$.prediction,tolerance=1e-12)))
}
if(parallel::detectCores() >= 2L) {
  z <- smf_batch_predict(b,d,batch_size=13L,workers=2L)
  stopifnot(isTRUE(all.equal(reference,z@prediction$.prediction,tolerance=1e-12)))
}

# Checkpoint corruption must fail on resume.
cp <- tempfile("cp-"); smf_batch_predict(b,d,batch_size=11L,checkpoint_dir=cp)
f <- list.files(cp,pattern="^batch-.*csv$",full.names=TRUE)[1]
cat("corrupt",file=f,append=TRUE)
stopifnot(inherits(try(smf_batch_predict(b,d,batch_size=11L,checkpoint_dir=cp,resume=TRUE),silent=TRUE),"try-error"))

# Optional pins smoke test uses a temporary local board.
if(requireNamespace("pins",quietly=TRUE)) {
  board <- pins::board_temp(versioned=TRUE)
  smf_pins_publish_bundle(board,bp,"smf-080-bundle")
  stopifnot("smf-080-bundle" %in% pins::pin_list(board))
}
message("sciModelFlowR 0.8.0 scalability/adapter validation completed.")
