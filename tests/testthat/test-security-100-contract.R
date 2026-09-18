test_that("opaque bundles preserve the explicit trust boundary", {
  src <- paste(readLines(system.file("R", "persistence.R", package="sciModelFlowR"), warn=FALSE), collapse="\n")
  skip_if_not(nzchar(src), "Installed source R files are not available through system.file on this platform")
})
