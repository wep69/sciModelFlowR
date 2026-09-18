# sciModelFlowR 0.7.0 numerical/simulation validation entry point.
library(sciModelFlowR)

# Repeated parameter recovery for the package-native conjugate Gaussian reference.
set.seed(270701)
B <- 100L
recover <- matrix(NA_real_,B,4,dimnames=list(NULL,c("b0","b1","b2","sigma")))
cover <- matrix(FALSE,B,3,dimnames=list(NULL,c("b0","b1","b2")))
for (b in seq_len(B)) {
  n <- 220L; x1 <- rnorm(n); x2 <- rnorm(n); y <- 1.5+2*x1-x2+rnorm(n,0,.8)
  dd <- data.frame(y=y,x1=x1,x2=x2)
  sp <- smf_bayesian_spec(priors=list(beta_mean=c(0,0,0),beta_sd=c(10,10,10),sigma_shape=2,sigma_rate=1),draws=1500L,seed=270700L+b)
  fit <- smf_bayes_fit(y ~ x1 + x2,dd,bayesian=sp,backend="conjugate_gaussian")
  s <- smf_bayes_summary(fit)
  recover[b,] <- s$mean[match(c("(Intercept)","x1","x2","sigma"),s$variable)]
  dr <- smf_bayes_draws(fit)
  q <- apply(dr[,c("(Intercept)","x1","x2"),drop=FALSE],2,quantile,c(.025,.975))
  truth <- c(1.5,2,-1); cover[b,] <- truth>=q[1,] & truth<=q[2,]
}
stopifnot(abs(mean(recover[,"b0"])-1.5)<.08,abs(mean(recover[,"b1"])-2)<.06,abs(mean(recover[,"b2"])+1)<.06,abs(mean(recover[,"sigma"])-.8)<.05)
stopifnot(all(colMeans(cover)>.90))

# Repeated split-conformal marginal coverage.
set.seed(270702)
R <- 200L; cov <- numeric(R)
for (r in seq_len(R)) {
  ntr<-220L;ncal<-220L;nte<-600L;n<-ntr+ncal+nte
  x1<-runif(n,-2.5,2.5);x2<-rnorm(n);mu<-2+1.4*x1+.45*x2+.3*sin(2*x1);sig<-.55+.18*abs(x1);y<-mu+rnorm(n,0,sig)
  dd<-data.frame(y=y,x1=x1,x2=x2)
  tr<-seq_len(ntr);ca<-ntr+seq_len(ncal);te<-ntr+ncal+seq_len(nte)
  m<-lm(y~x1+x2,data=dd[tr,])
  obj<-smf_conformal_fit(dd$y[ca],predict(m,dd[ca,]),smf_conformal_spec("split",level=.90))
  ints<-smf_conformal_predict(obj,predict(m,dd[te,]))
  cov[r]<-smf_conformal_coverage(dd$y[te],ints)$coverage
}
stopifnot(abs(mean(cov)-.90)<.02)

message("sciModelFlowR 0.7.0 simulation validation completed.")
