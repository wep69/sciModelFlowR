test_that("design metadata validates and summarizes", {
  d <- data.frame(id=1:8,field=rep(c("A","B"),each=4),time=rep(1:4,2),x=runif(8),y=runif(8))
  des <- smf_design_spec(id_column="id",group_columns="field",repeated_unit="field",time_column="time")
  warnings <- smf_validate_design(d,des,smf_resampling_spec("holdout"))
  codes <- vapply(warnings,function(w)w@code,character(1))
  expect_true("PSEUDOREPLICATION_RISK_RANDOM_SPLIT" %in% codes)
  s <- smf_design_summary(d,des)
  expect_equal(s$group_columns$field,2)
})

test_that("coordinates must be numeric", {
  d <- data.frame(x=c("a","b"),y=1:2,z=1:2)
  des <- smf_design_spec(coordinate_columns=c("x","y"))
  expect_error(smf_validate_design(d,des))
})
