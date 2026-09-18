# sciModelFlowR 0.8.0 local runtime validation
stopifnot(as.character(packageVersion("sciModelFlowR")) == "0.8.0")
library(sciModelFlowR)

d <- smf_load_dataset("gold_linear_regression")
spec <- smf_experiment_spec(
  task=smf_task_spec("regression","yield"),
  data=smf_data_spec("yield",c("nitrogen","rainfall","soil_n"),id_column="obs_id"),
  design=smf_design_spec(id_column="obs_id"),
  preprocessing=smf_preprocess_spec("median",center=TRUE,scale=TRUE),
  resampling=smf_resampling_spec("holdout",train_prop=.8,seed=260915L),
  model=smf_model_spec("linear_regression","stats"),
  metrics=list(smf_metric_spec("rmse")),
  tracking=smf_tracking_spec("none"), persistence=smf_persistence_spec(),
  deployment=smf_deployment_spec(), scalability=smf_scalability_spec(chunk_size=17L)
)
r <- smf_fit_experiment(spec,d)
stopifnot(length(r@manifest@hardware) > 0L)

# Local tracking and resume.
track_root <- tempfile("smf-track-")
tr <- smf_tracker_local(track_root,"validation-080")
run <- smf_start_run(tr,run_name="gold-linear")
smf_log_result(run,r)
run <- smf_end_run(run,"interrupted")
run2 <- smf_start_run(tr,resume_run_id=run@run_id)
stopifnot(identical(run2@run_id,run@run_id), isTRUE(run2@metadata$resumed))
run2 <- smf_end_run(run2,"finished")
stopifnot(nrow(smf_list_runs(tr))==1L)

# Portable safe bundle round-trip.
bundle_dir <- tempfile("smf-bundle-")
smf_save_bundle(r,bundle_dir,mode="portable")
v <- smf_validate_bundle(bundle_dir)
stopifnot(v@valid, length(v@unsafe_components)==0L)
b <- smf_load_bundle(bundle_dir)
nd <- d[1:25,,drop=FALSE]
p_live <- as.numeric(smf_predict(r,nd))
p_bundle <- as.numeric(smf_predict_bundle(b,nd))
stopifnot(isTRUE(all.equal(p_live,p_bundle,tolerance=1e-12)))

# Corruption must be rejected.
corrupt <- tempfile("smf-corrupt-")
dir.create(corrupt)
file.copy(list.files(bundle_dir,full.names=TRUE,all.files=TRUE,no..=TRUE),corrupt,recursive=TRUE)
cat("corruption",file=file.path(corrupt,"schema.json"),append=TRUE)
stopifnot(inherits(try(smf_validate_bundle(corrupt),silent=TRUE),"try-error"))

# Opaque bundle trust boundary.
opaque <- tempfile("smf-opaque-")
smf_save_bundle(r,opaque,mode="opaque")
stopifnot(inherits(try(smf_load_bundle(opaque),silent=TRUE),"try-error"))
bo <- smf_load_bundle(opaque,trusted=TRUE)
stopifnot(isTRUE(all.equal(as.numeric(smf_predict_bundle(bo,nd)),p_live,tolerance=1e-12)))

# Resumable batch prediction.
cp <- tempfile("smf-batch-")
a <- smf_batch_predict(b,d,batch_size=17L,checkpoint_dir=cp)
a2 <- smf_batch_predict(b,d,batch_size=17L,checkpoint_dir=cp,resume=TRUE)
stopifnot(a2@resumed,isTRUE(all.equal(a@prediction,a2@prediction,tolerance=1e-12)))
stopifnot(isTRUE(all.equal(a@prediction$.prediction,as.numeric(smf_predict_bundle(b,d)),tolerance=1e-12)))

# Iterator contract.
it <- smf_data_iterator(d,19L)
ids <- unlist(smf_map_iterator(it,function(z)z$obs_id),use.names=FALSE)
stopifnot(identical(ids,d$obs_id))

# Hardware schema.
h <- smf_hardware_info()
stopifnot(all(c("logical_cores","physical_cores","gpu_available","cuda_available","cuda_runtime") %in% names(h)))

message("sciModelFlowR 0.8.0 core runtime validation completed.")
