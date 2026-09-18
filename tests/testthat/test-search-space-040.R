test_that("conditional search spaces generate valid configurations", {
  sp <- smf_search_space(
    booster = smf_param_fct(c("linear","tree")),
    depth = smf_param_int(2, 4, depends_on=list(param="booster", values="tree")),
    rate = smf_param_dbl(0.01, 0.2, log=TRUE)
  )
  g <- smf_search_grid(sp, levels=3)
  expect_true(nrow(g) >= 3)
  expect_true(all(is.na(g$depth[g$booster=="linear"])))
  r1 <- smf_search_random(sp, 10, seed=77)
  r2 <- smf_search_random(sp, 10, seed=77)
  expect_equal(r1, r2)
})

test_that("search spaces survive portable serialization", {
  sp <- smf_search_space(k=smf_param_int(1,9), lambda=smf_param_dbl(1e-4,1,log=TRUE))
  back <- smf_from_json(smf_to_json(sp))
  expect_s3_class(S7::S7_class(back), "S7_class")
  expect_equal(names(back@parameters), c("k","lambda"))
})
