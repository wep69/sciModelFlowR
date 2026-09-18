test_that("stats adapter matches direct lm predictions", {
  set.seed(20); x<-data.frame(x1=rnorm(50),x2=rnorm(50)); y<-1+2*x$x1-.5*x$x2+rnorm(50,.1)
  task<-smf_task_spec("regression","y"); mod<-smf_model_spec("linear_regression","stats")
  a<-smf_fit_model(task,mod,x,y); p<-smf_predict_model(a,task,x,"response")
  direct<-stats::lm(y~.,data=x)
  expect_equal(p,as.numeric(stats::predict(direct,newdata=x)),tolerance=1e-10)
})

test_that("stats binary adapter returns two normalized probability columns", {
  set.seed(21); x<-data.frame(x=rnorm(80)); y<-factor(ifelse(runif(80)<plogis(x$x),"yes","no"),levels=c("no","yes"))
  task<-smf_task_spec("binary","y",positive_label="yes"); mod<-smf_model_spec("logistic_regression","stats")
  a<-smf_fit_model(task,mod,x,y); p<-smf_predict_model(a,task,x,"prob")
  expect_equal(colnames(p),c("no","yes")); expect_true(all(abs(rowSums(p)-1)<1e-10))
})

test_that("optional tidymodels adapter follows parsnip probability contract", {
  skip_if_not_installed("parsnip")
  x<-data.frame(x=c(-2,-1,0,1,2,3)); y<-factor(c("no","no","no","yes","yes","yes"),levels=c("no","yes"))
  task<-smf_task_spec("binary","y",positive_label="yes"); mod<-smf_model_spec("logistic_regression","tidymodels",parameters=list(model_engine="glm"))
  a<-smf_fit_model(task,mod,x,y); p<-smf_predict_model(a,task,x,"prob")
  expect_true(all(abs(rowSums(p)-1)<1e-8))
})

test_that("binary positive label defines the probability-column order", {
  set.seed(22)
  x <- data.frame(x = rnorm(80))
  # Put the scientifically positive class first in the incoming factor to
  # verify that the adapter standardizes it to the second probability column.
  y <- factor(ifelse(runif(80) < plogis(x$x), "event", "none"), levels = c("event", "none"))
  task <- smf_task_spec("binary", "y", positive_label = "event")
  mod <- smf_model_spec("logistic_regression", "stats")
  a <- smf_fit_model(task, mod, x, y)
  p <- smf_predict_model(a, task, x, "prob")
  expect_equal(colnames(p), c("none", "event"))
  expect_true(all(abs(rowSums(p) - 1) < 1e-10))
})
