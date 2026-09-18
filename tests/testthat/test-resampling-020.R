test_that("group V-fold never splits a declared group", {
  d <- data.frame(id=sprintf("R%03d",1:60), field=rep(sprintf("F%02d",1:12),each=5), x=rnorm(60), y=rnorm(60))
  r <- smf_group_vfold_cv(d,"field",v=4,id_column="id",seed=12L)
  expect_true(S7::S7_inherits(r,sciModelFlowR:::ResampleCollection))
  for(s in r@splits) {
    tr <- unique(d$field[s@train_index]); te <- unique(d$field[s@test_index])
    expect_length(intersect(tr,te),0)
  }
})

test_that("time validation trains strictly before assessment", {
  d <- data.frame(id=1:30,time=rep(1:10,each=3),x=rnorm(30))
  r <- smf_time_cv(d,"time",initial=5,assess=2,id_column="id")
  for(s in r@splits) expect_lt(max(d$time[s@train_index]),min(d$time[s@test_index]))
})

test_that("spatial blocks are reproducible from configuration", {
  d <- expand.grid(x=1:8,y=1:6); d$id <- seq_len(nrow(d))
  a <- smf_spatial_cv(d,c("x","y"),v=4,id_column="id",seed=99L,n_x=4,n_y=3)
  b <- smf_spatial_cv(d,c("x","y"),v=4,id_column="id",seed=99L,n_x=4,n_y=3)
  expect_identical(a@manifest_hash,b@manifest_hash)
})

test_that("ordinary row-wise CV is blocked for grouped designs", {
  d <- data.frame(id=1:20,subject=rep(1:5,each=4),y=rnorm(20))
  design <- smf_design_spec(id_column="id",group_columns="subject",repeated_unit="subject")
  spec <- smf_resampling_spec("kfold",n_splits=5)
  expect_error(smf_make_resampler(d,spec,design),class="smf_design_mismatch_error")
})

test_that("external validation isolates declared domains", {
  d <- data.frame(id=1:12,domain=rep(c("dev","external"),c(8,4)),x=rnorm(12))
  s <- smf_external_split(d,"domain","external",id_column="id")
  expect_true(all(d$domain[s@test_index]=="external"))
  expect_true(all(d$domain[s@train_index]=="dev"))
})
