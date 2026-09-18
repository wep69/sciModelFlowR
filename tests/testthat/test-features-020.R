test_that("learned selection cannot be fitted globally in a managed workflow", {
  d <- data.frame(x1=rnorm(20),x2=rnorm(20),y=rnorm(20))
  fs <- smf_feature_spec("mutual_information",n_features=1L)
  expect_error(smf_select_features(d,"y",fs,context="global"),class="smf_leakage_error")
})

test_that("correlation filtering is fitted on a training partition", {
  set.seed(1); x <- rnorm(40); d <- data.frame(x1=x,x2=x+rnorm(40,0,.001),x3=rnorm(40),y=rnorm(40))
  fs <- smf_feature_spec("correlation",threshold=.95)
  out <- smf_select_features(d,"y",fs,context="training")
  expect_true(length(intersect(out@selected,c("x1","x2")))==1L)
  expect_true("x3" %in% out@selected)
})

test_that("feature stability is estimated across resampling folds", {
  d <- data.frame(id=1:60,x1=rnorm(60),x2=rnorm(60),y=rnorm(60))
  r <- smf_vfold_cv(d,5,id_column="id",seed=2L)
  fs <- smf_feature_spec("mutual_information",n_features=1L)
  out <- smf_feature_select_resamples(d,"y",fs,r,id_column="id")
  expect_equal(nrow(out@stability),2L)
  expect_true(all(out@stability$frequency>=0 & out@stability$frequency<=1))
})

test_that("PCA is a training-fitted representation", {
  d <- data.frame(x1=rnorm(30),x2=rnorm(30),y=rnorm(30))
  fs <- smf_feature_spec("pca",n_features=2L)
  out <- smf_build_representation(d,"y",fs,context="training")
  expect_equal(ncol(out@transformed),2L)
})


test_that("RFE and sequential selection are implemented on training data", {
  set.seed(21)
  n <- 80
  d <- data.frame(x1=rnorm(n), x2=rnorm(n), x3=rnorm(n))
  d$y <- 4*d$x1 - 2*d$x2 + rnorm(n, sd=.4)
  rfe <- smf_select_features(d,"y",smf_feature_spec("rfe",n_features=2L,parameters=list(criterion="bic")),context="training")
  seqf <- smf_select_features(d,"y",smf_feature_spec("sequential",n_features=2L,parameters=list(criterion="bic",direction="forward")),context="training")
  expect_equal(length(rfe@selected),2L)
  expect_equal(length(seqf@selected),2L)
  expect_true("x1" %in% rfe@selected)
  expect_true("x1" %in% seqf@selected)
})

test_that("PCA state is applied without refitting assessment data", {
  set.seed(9)
  tr <- data.frame(x1=rnorm(30),x2=rnorm(30),y=rnorm(30))
  te <- data.frame(x1=rnorm(10,10,2),x2=rnorm(10,-5,1))
  fs <- smf_feature_spec("pca",n_features=2L)
  rep <- smf_build_representation(tr,"y",fs,context="training")
  z <- smf_apply_representation(rep,te)
  expect_equal(nrow(z),nrow(te))
  expect_equal(names(z),c("PC1","PC2"))
  expect_equal(rep@training_hash, smf_data_hash(tr))
})
