test_that("all twelve Gold files are available", {
  expect_length(smf_list_datasets(),12)
  for(nm in smf_list_datasets()) expect_true(nrow(smf_load_dataset(nm))>0)
})

test_that("Gold hashes validate", {
  x <- smf_run_gold_validation()
  expect_true(all(x$passed))
})
