.onLoad <- function(libname, pkgname) {
  S7::methods_register()
}

# torch nn_module() closures use NSE pronoun `self` (no visible binding).
# ggplot2::aes() in smf_plot() uses data-column NSE names (no visible binding).
utils::globalVariables(c("self", "mean_probability", "observed_frequency", "n", "observed", "predicted", "residual"))
