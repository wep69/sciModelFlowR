test_that("scientific warning records retain severity and evidence", {
  w <- smf_warning_record("TEST_CODE","Example warning","high",evidence=list(x=1),suggested_action="Inspect design.")
  expect_equal(w@severity,"high")
  expect_equal(w@code,"TEST_CODE")
  expect_equal(w@evidence$x,1)
})

test_that("stats reference backend advertises expected capabilities", {
  rec <- smf_backend_capabilities("stats")
  expect_true(rec$capabilities@regression)
  expect_true(rec$capabilities@classification)
  expect_error(smf_require_capability("stats","gpu"),class="smf_capability_error")
})
