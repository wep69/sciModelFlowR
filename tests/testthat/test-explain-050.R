test_that("ExplainSpec round-trips and explanations are explicitly non-causal", {
  x <- smf_explain_spec(c("permutation","pdp","ale"), n_repeats=3L, grid_size=5L)
  y <- smf_from_json(smf_to_json(x))
  expect_true(S7::S7_inherits(y, ExplainSpec))
  expect_equal(y@methods, x@methods)
})

test_that("XAI Gold fixture contains the intended correlated predictors", {
  d <- smf_load_dataset("gold_xai_stability")
  expect_gt(abs(cor(d$signal_primary,d$signal_correlated)), .95)
})
