test_that("batch prediction preserves order and can resume", {
  d <- smf_load_dataset("gold_linear_regression")
  spec <- smf_experiment_spec(smf_task_spec("regression","yield"),smf_data_spec("yield",c("nitrogen","rainfall","soil_n"),id_column="obs_id"),smf_design_spec(id_column="obs_id"),smf_preprocess_spec("median",TRUE,TRUE),smf_resampling_spec("holdout",seed=17L),smf_model_spec("linear_regression","stats"))
  r <- smf_fit_experiment(spec,d); bdir<-tempfile("bundle-"); smf_save_bundle(r,bdir,"portable"); b<-smf_load_bundle(bdir)
  cp<-tempfile("batch-")
  a<-smf_batch_predict(b,d,batch_size=17L,checkpoint_dir=cp)
  b2<-smf_batch_predict(b,d,batch_size=17L,checkpoint_dir=cp,resume=TRUE)
  expect_equal(a@prediction,b2@prediction,tolerance=1e-12)
  expect_true(b2@resumed)
  expect_equal(a@n_rows,nrow(d))
})

test_that("iterator visits every row exactly once", {
  x<-data.frame(id=1:23); it<-smf_data_iterator(x,5L); out<-smf_map_iterator(it,function(z)z$id)
  expect_equal(unlist(out),1:23)
})
