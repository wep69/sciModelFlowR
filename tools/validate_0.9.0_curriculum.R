# sciModelFlowR 0.9.0 curriculum validation
nb <- list.files("inst/notebooks/jupyter", pattern="\\.ipynb$", full.names=TRUE)
stopifnot(length(nb) == 27L)
invisible(lapply(nb, jsonlite::fromJSON, simplifyVector=FALSE))
