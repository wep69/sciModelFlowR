test_that("hardware record has CPU/GPU/CUDA fields", {
  h<-smf_hardware_info(); expect_true(all(c("logical_cores","gpu_available","cuda_available","cuda_runtime") %in% names(h)))
})

test_that("ONNX export never claims unsupported equivalence", {
  expect_error(smf_export_onnx(NULL,tempfile(fileext=".onnx")),class="smf_capability_error")
})
