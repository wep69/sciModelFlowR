test_that("0.6 architectures preserve declared scientific shapes", {
  a <- smf_mlp(4, hidden=c(16L,8L), output_dim=1L)
  expect_true(S7::S7_inherits(a, DLArchitecture))
  expect_equal(a@kind,"mlp")
  expect_equal(a@input_shape,4L)
  expect_equal(smf_from_json(smf_to_json(a))@kind,"mlp")
  expect_equal(smf_lstm(3)@kind,"lstm")
  expect_equal(smf_cnn2d(c(3,32,32))@modality,"image")
})
