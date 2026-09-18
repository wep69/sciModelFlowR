test_that("grid and random objective tuning produce reproducible archives", {
  sp <- smf_search_space(x=smf_param_dbl(values=c(-2,0,2)))
  obj <- list(smf_metric_spec("loss", direction="minimize"))
  tune <- smf_tuning_spec("grid", budget=3, objectives=obj, seed=99)
  a <- smf_tune_objective(sp,tune,function(cfg)c(loss=(cfg$x-1)^2))
  expect_equal(nrow(a@archive),3)
  expect_equal(a@selected$x[[1]],0) # tie is resolved by first minimum in deterministic grid order
  expect_true(isTRUE(a@provenance$final_test_used == FALSE))
  tune2 <- smf_tuning_spec("random", budget=5, objectives=obj, seed=99)
  r1 <- smf_tune_objective(sp,tune2,function(cfg)c(loss=(cfg$x-1)^2))
  r2 <- smf_tune_objective(sp,tune2,function(cfg)c(loss=(cfg$x-1)^2))
  expect_equal(r1@archive$x,r2@archive$x)
})

test_that("multi-objective tuning preserves Pareto set and requires explicit compromise", {
  sp <- smf_search_space(x=smf_param_dbl(values=c(0,0.5,1)))
  objs <- list(smf_metric_spec("error","minimize"), smf_metric_spec("cost","minimize"))
  tune <- smf_tuning_spec("grid",3,objectives=objs)
  z <- smf_tune_objective(sp,tune,function(cfg)c(error=(cfg$x-1)^2,cost=cfg$x^2))
  expect_null(z@selected)
  expect_true(nrow(z@pareto)>=2)
  rule <- list(type="weighted_sum",weights=c(error=.7,cost=.3))
  tune2 <- smf_tuning_spec("grid",3,objectives=objs,decision_rule=rule)
  z2 <- smf_tune_objective(sp,tune2,function(cfg)c(error=(cfg$x-1)^2,cost=cfg$x^2))
  expect_true(nrow(z2@selected)==1)
})

test_that("data marked as final test are rejected by managed tuning", {
  d <- data.frame(x=1:5,y=1:5)
  attr(d,"smf_partition_role") <- "final_test"
  task <- smf_task_spec("regression","y")
  ds <- smf_data_spec("y","x")
  spec <- smf_experiment_spec(task,ds,model=smf_model_spec("lm","stats"))
  expect_error(smf_tune(spec,d,smf_search_space(dummy=smf_param_int(values=1:2)),smf_tuning_spec("grid",2)),class="smf_leakage_error")
})
