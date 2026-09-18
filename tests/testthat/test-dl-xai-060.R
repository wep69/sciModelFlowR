test_that("gradient explanations are structurally non-causal", {
  x <- DLGradientExplanation(method="saliency",values=matrix(0,1,2),target=1L,baseline=NULL,layer=character(),causal_interpretation=FALSE,provenance=list())
  expect_false(x@causal_interpretation)
  y <- smf_from_json(smf_to_json(x))
  expect_false(y@causal_interpretation)
})

test_that("Grad-CAM requires explicit activation contract", {
  expect_error(smf_dl_gradcam(NULL,array(0,c(1,1,4,4)),"conv"),class="smf_validation_error")
})
