test_that("structured tensor shape guard is explicit", {
  a <- smf_cnn1d(c(1L,24L))
  x <- array(0,dim=c(10L,1L,24L))
  expect_invisible(sciModelFlowR:::.smf_dl_validate_shape(x,a))
  bad <- array(0,dim=c(10L,24L,1L))
  expect_error(sciModelFlowR:::.smf_dl_validate_shape(bad,a),class="smf_validation_error")
})
