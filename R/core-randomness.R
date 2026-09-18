#' Execute code under an isolated seed
#' @export
smf_with_seed <- function(seed, code) withr::with_seed(as.integer(seed), code)

#' Return current RNG information
#' @export
smf_rng_info <- function() list(kind=RNGkind(), has_seed=exists(".Random.seed", envir=.GlobalEnv, inherits=FALSE))
