test_that("holdout is disjoint and reproducible", {
  d <- data.frame(id=sprintf("O%03d",1:100),x=rnorm(100))
  a <- smf_holdout_split(d,.8,id_column="id",seed=123L)
  b <- smf_holdout_split(d,.8,id_column="id",seed=123L)
  expect_length(intersect(a@train_index,a@test_index),0)
  expect_identical(a@hash,b@hash)
  expect_identical(a@train_ids,b@train_ids)
})

test_that("split manifest restores ID membership", {
  d <- data.frame(id=sprintf("O%03d",1:20),x=1:20)
  s <- smf_holdout_split(d,.7,id_column="id",seed=4L)
  m <- smf_split_manifest(s)
  d2 <- d[rev(seq_len(nrow(d))),]
  s2 <- smf_import_split_manifest(d2,m,"id")
  expect_setequal(s@train_ids,s2@train_ids)
  expect_setequal(s@test_ids,s2@test_ids)
})
