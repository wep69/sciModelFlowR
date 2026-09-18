test_that("audit detects an exact target copy", {
  d <- data.frame(id=1:6,x=1:6,y=c(2,4,6,8,10,12),copy=c(2,4,6,8,10,12))
  spec <- smf_data_spec("y",c("x","copy"),id_column="id")
  a <- smf_audit_data(d,spec)
  codes <- vapply(a@leakage,function(w)w@code,character(1))
  expect_true("LEAKAGE_EXACT_TARGET_COPY" %in% codes)
})

test_that("schema rejects missing columns", {
  d <- data.frame(x=1:5,y=2:6)
  expect_error(smf_validate_schema(d,smf_data_spec("y",c("z"))))
})
