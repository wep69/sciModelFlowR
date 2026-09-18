test_that("checkpoint metadata records SHA-256 without trusting payload", {
  p <- tempfile(fileext=".pt")
  writeBin(charToRaw("checkpoint-fixture"),p)
  ck <- smf_dl_checkpoint(p)
  expect_true(S7::S7_inherits(ck,DLCheckpoint))
  expect_equal(nchar(ck@sha256),64L)
  expect_false(ck@trusted)
})

test_that("checkpoint load requires explicit trust before deserialization", {
  skip_if_not_installed("torch")
  p <- tempfile(fileext=".pt"); writeBin(charToRaw("not-a-real-checkpoint"),p)
  ck <- smf_dl_checkpoint(p)
  expect_error(smf_dl_load_checkpoint(ck,model=list(),trusted=FALSE),class="smf_serialization_error")
})
