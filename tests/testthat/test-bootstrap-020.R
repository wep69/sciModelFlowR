test_that("IID bootstrap is blocked for declared clustered data", {
  d <- data.frame(id=1:30,field=rep(1:6,each=5),y=rnorm(30))
  des <- smf_design_spec(id_column="id",group_columns="field")
  bs <- smf_bootstrap_spec("case",n_resamples=20)
  expect_error(smf_bootstrap(d,bs,function(z)c(mean=mean(z$y)),des),class="smf_design_mismatch_error")
})

test_that("cluster bootstrap preserves cluster sampling unit", {
  d <- data.frame(id=1:30,field=rep(1:6,each=5),y=rnorm(30))
  des <- smf_design_spec(id_column="id",group_columns="field")
  bs <- smf_bootstrap_spec("cluster",n_resamples=40,sampling_unit="field",seed=2L)
  out <- smf_bootstrap(d,bs,function(z)c(mean=mean(z$y)),des)
  expect_true(S7::S7_inherits(out,sciModelFlowR:::BootstrapResult))
  expect_equal(out@successful,40L)
  expect_true(all(c("lower","upper") %in% colnames(out@interval)))
})

test_that("moving-block bootstrap accepts declared temporal dependence", {
  d <- data.frame(id=1:50,time=1:50,y=sin(1:50/5)+rnorm(50,.1))
  des <- smf_design_spec(id_column="id",time_column="time")
  bs <- smf_bootstrap_spec("moving_block",n_resamples=25,block_length=5L,seed=7L)
  out <- smf_bootstrap(d,bs,function(z)c(mean=mean(z$y)),des)
  expect_equal(out@failed,0L)
})

test_that("temporal bootstrap does not silently ignore grouping dependence", {
  d <- data.frame(id=1:12, plant=rep(letters[1:4], each=3), time=rep(1:3,4), y=rnorm(12))
  des <- smf_design_spec(groups="plant", time="time")
  bs <- smf_bootstrap_spec(method="moving_block", n_resamples=10, block_length=2)
  expect_error(smf_validate_bootstrap_design(d, bs, des), class="smf_design_mismatch_error")
})

test_that("generic BCa is restricted to certified case bootstrap", {
  d <- data.frame(stratum=rep(c("a","b"), each=8), y=rnorm(16))
  bs <- smf_bootstrap_spec(method="stratified", n_resamples=20, sampling_unit="stratum", interval="bca")
  expect_error(smf_bootstrap(d, bs, function(z) c(mean=mean(z$y))), class="smf_bootstrap_error")
})


test_that("studentized intervals use replicate-specific standard errors", {
  set.seed(4)
  d <- data.frame(y=rnorm(35,3,2))
  stat <- function(z) c(mean=mean(z$y))
  sefun <- function(z) c(mean=stats::sd(z$y)/sqrt(nrow(z)))
  bs <- smf_bootstrap_spec("case",n_resamples=80,interval="studentized",seed=12L,parameters=list(standard_error=sefun))
  out <- smf_bootstrap(d,bs,stat)
  expect_true(all(is.finite(out@interval)))
  expect_lt(out@interval["mean","lower"],out@interval["mean","upper"])
})
